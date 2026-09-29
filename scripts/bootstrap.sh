#!/usr/bin/env bash
# Sets a repo up for the ProjectTemplate process: labels, the project board,
# its fields, the repo link and the automation variables. Idempotent; a second
# run only reports what already exists.
#
# Usage: bootstrap.sh [<owner>/<repo>] [--areas a,b,c] [--project N | --copy-from N]
#                     [--prune-defaults] [--mark-template]

set -euo pipefail

repo=""
areas=""
project=""
copy_from=""
prune_defaults=0
mark_template=0

while [ $# -gt 0 ]; do
  case "$1" in
    --areas) areas="$2"; shift 2 ;;
    --project) project="$2"; shift 2 ;;
    --copy-from) copy_from="$2"; shift 2 ;;
    --prune-defaults) prune_defaults=1; shift ;;
    --mark-template) mark_template=1; shift ;;
    -h|--help) sed -n '2,7p' "$0"; exit 0 ;;
    *) repo="$1"; shift ;;
  esac
done

[ -n "$repo" ] || repo=$(gh repo view --json nameWithOwner --jq .nameWithOwner)
owner="${repo%%/*}"
name="${repo##*/}"

say()  { printf '%s\n' "$*"; }
skip() { printf '  = %s\n' "$*"; }
did()  { printf '  + %s\n' "$*"; }

#region Preflight

gh auth status >/dev/null || { say "gh is not logged in"; exit 1; }
gh project list --owner "$owner" --limit 1 >/dev/null 2>&1 \
  || { say "The token lacks the project scope. Run: gh auth refresh -s project"; exit 1; }

#endregion

#region Labels

say "Labels on $repo"

labels=$(gh label list --repo "$repo" --limit 200 --json name --jq '.[].name')

has_label() { grep -qxF -- "$1" <<<"$labels"; }

canonical=(
  "type:bug|d73a4a|Something is broken"
  "type:feature|0e8a16|New capability"
  "type:refactor|5319e7|Restructuring without behaviour change"
  "type:docs|0075ca|Documentation"
  "type:perf|fbca04|Performance work"
  "type:chore|cfd3d7|Maintenance"
  "type:spike|d4c5f9|Time-boxed investigation"
  "type:test|bfd4f2|Tests"
  "prio:p0|b60205|main is broken"
  "prio:p1|d93f0b|This milestone"
  "prio:p2|fbca04|Next milestone"
  "prio:p3|c2e0c6|Someday"
  "status:blocked|000000|Blocked on something else"
  "status:deferred|cfd3d7|Intentionally postponed"
  "status:needs-design|5319e7|Needs a design decision first"
  "decision|d876e3|A question only the director can answer"
  "epic|3d1e8f|An outcome spanning several pull requests"
  "area:docs|1d76db|Area: docs"
  "area:build|1d76db|Area: build"
  "area:ci|1d76db|Area: ci"
)

if [ -n "$areas" ]; then
  IFS=',' read -ra extra_areas <<<"$areas"
  for extra in "${extra_areas[@]}"; do
    canonical+=("area:${extra}|1d76db|Area: ${extra}")
  done
fi

for entry in "${canonical[@]}"; do
  IFS='|' read -r lname lcolor ldesc <<<"$entry"
  # A spaced variant like "type: bug" is renamed in place, which keeps its
  # issue associations
  spaced="${lname/:/: }"
  if [ "$spaced" != "$lname" ] && has_label "$spaced" && ! has_label "$lname"; then
    gh label edit "$spaced" --repo "$repo" --name "$lname" >/dev/null
    labels+=$'\n'"$lname"
    did "renamed '$spaced' to '$lname'"
  fi
  if has_label "$lname"; then
    skip "$lname exists"
  else
    gh label create "$lname" --repo "$repo" --color "$lcolor" --description "$ldesc" >/dev/null
    did "created $lname"
  fi
done

# GitHub's default labels go only when nothing carries them. Extra local
# labels are always left alone: the scheme is a floor, not a ceiling.
if [ "$prune_defaults" = 1 ]; then
  for dflt in bug documentation duplicate enhancement "good first issue" "help wanted" invalid question wontfix; do
    has_label "$dflt" || continue
    count=$(gh api --method GET search/issues -f q="repo:$repo label:\"$dflt\"" --jq .total_count)
    if [ "$count" = "0" ]; then
      gh label delete "$dflt" --repo "$repo" --yes >/dev/null
      did "deleted default label '$dflt'"
    else
      skip "kept '$dflt': $count issues carry it"
    fi
  done
fi

#endregion

#region Board

say "Board"

if [ -n "$project" ]; then
  num="$project"
  skip "using project $num as given"
else
  num=$(gh project list --owner "$owner" --limit 100 --format json \
        --jq ".projects[] | select(.title == \"$name\") | .number" | head -1)
  if [ -n "$num" ]; then
    skip "project '$name' exists as number $num"
  elif [ -n "$copy_from" ]; then
    num=$(gh project copy "$copy_from" --source-owner "$owner" --target-owner "$owner" \
          --title "$name" --format json --jq .number)
    did "copied project $copy_from to '$name' (number $num), fields and views included"
  else
    num=$(gh project create --owner "$owner" --title "$name" --format json --jq .number)
    did "created project '$name' (number $num)"
  fi
fi

fields=$(gh project field-list "$num" --owner "$owner" --format json --jq '.fields[].name')

has_field() { grep -qxF -- "$1" <<<"$fields"; }

# Creates the field unless one with that name exists.
ensure_field() {
  local fname="$1" ftype="$2" fopts="${3:-}"
  if has_field "$fname"; then
    skip "field $fname exists"
  elif [ -n "$fopts" ]; then
    gh project field-create "$num" --owner "$owner" --name "$fname" \
      --data-type "$ftype" --single-select-options "$fopts" >/dev/null
    did "created field $fname"
  else
    gh project field-create "$num" --owner "$owner" --name "$fname" \
      --data-type "$ftype" >/dev/null
    did "created field $fname"
  fi
}

ensure_field "Estimate" "NUMBER"
ensure_field "Priority" "SINGLE_SELECT" "P0,P1,P2,P3"
ensure_field "Start date" "DATE"
ensure_field "Target date" "DATE"

# Status is a built-in field that field-create cannot touch, so its options go
# through GraphQL. Existing option ids are passed back where the names match,
# which keeps those cards' statuses.
status_id=$(gh project field-list "$num" --owner "$owner" --format json \
  --jq '.fields[] | select(.name == "Status") | .id')

# shellcheck disable=SC2016  # the $id is a GraphQL variable, not shell
existing=$(gh api graphql -f id="$status_id" -f query='
  query($id: ID!) {
    node(id: $id) { ... on ProjectV2SingleSelectField { options { id name } } }
  }' --jq '.data.node.options[] | [.id, .name] | @tsv')

wanted=("Backlog|GRAY" "Ready|BLUE" "In progress|YELLOW" "In review|PURPLE" "Done|GREEN")

if [ "$(cut -f2 <<<"$existing")" = $'Backlog\nReady\nIn progress\nIn review\nDone' ]; then
  skip "Status options are canonical"
else
  while IFS=$'\t' read -r _ oname; do
    case "$oname" in
      Backlog|Ready|"In progress"|"In review"|Done) ;;
      *) say "  ! Status option '$oname' is dropped; its items will read 'No status'" ;;
    esac
  done <<<"$existing"
  opts=""
  for w in "${wanted[@]}"; do
    IFS='|' read -r oname ocolor <<<"$w"
    oid=$(awk -F'\t' -v n="$oname" '$2 == n {print $1}' <<<"$existing" | head -1)
    if [ -n "$oid" ]; then
      opts+="{id: \"$oid\", name: \"$oname\", color: $ocolor, description: \"\"},"
    else
      opts+="{name: \"$oname\", color: $ocolor, description: \"\"},"
    fi
  done
  gh api graphql -f query="
    mutation {
      updateProjectV2Field(input: {fieldId: \"$status_id\", singleSelectOptions: [${opts%,}]}) {
        projectV2Field { ... on ProjectV2SingleSelectField { id } }
      }
    }" >/dev/null
  did "set Status options to Backlog, Ready, In progress, In review, Done"
fi

# shellcheck disable=SC2016  # $o and $r are GraphQL variables, not shell
linked=$(gh api graphql -f o="$owner" -f r="$name" -f query='
  query($o: String!, $r: String!) {
    repository(owner: $o, name: $r) { projectsV2(first: 50) { nodes { number } } }
  }' --jq '.data.repository.projectsV2.nodes[].number')
if grep -qx "$num" <<<"$linked"; then
  skip "project linked to $repo"
else
  gh project link "$num" --owner "$owner" --repo "$repo" >/dev/null
  did "linked project $num to $repo"
fi

script_dir=$(cd "$(dirname "$0")" && pwd)
readme_file="$script_dir/../docs/project-readme.md"
if [ "$(gh project view "$num" --owner "$owner" --format json --jq .readme)" != "" ]; then
  skip "board README present"
elif [ -f "$readme_file" ]; then
  gh project edit "$num" --owner "$owner" --readme "$(cat "$readme_file")" >/dev/null
  did "set the board README"
else
  say "  ! docs/project-readme.md not found; board README left empty"
fi

#endregion

#region Automation wiring

say "Automation"

url="https://github.com/users/$owner/projects/$num"
if [ "$(gh api "repos/$repo/actions/variables/PROJECT_URL" --jq .value 2>/dev/null || true)" = "$url" ]; then
  skip "PROJECT_URL is set"
else
  gh variable set PROJECT_URL --repo "$repo" --body "$url"
  did "set PROJECT_URL to $url"
fi

if [ -n "${ADD_TO_PROJECT_PAT:-}" ]; then
  gh secret set ADD_TO_PROJECT_PAT --repo "$repo" --body "$ADD_TO_PROJECT_PAT"
  did "set the ADD_TO_PROJECT_PAT secret"
fi

if [ "$mark_template" = 1 ]; then
  if [ "$(gh repo view "$repo" --json isTemplate --jq .isTemplate)" = "true" ]; then
    skip "$repo is a template repository"
  else
    gh repo edit "$repo" --template >/dev/null
    did "marked $repo as a template repository"
  fi
fi

#endregion

cat <<EOF

Manual checklist. No API reaches these:

* Board workflows ($url/settings/workflows):
  * Item added to project -> Status: Backlog
  * Item closed -> Status: Done
  * Pull request merged -> Status: Done
  * Auto-archive items, and Auto-add if not using ADD_TO_PROJECT_PAT
* Views, unless --copy-from supplied them:
  * Board, grouped by Status, with the Estimate field sum shown
  * By milestone, a table grouped by milestone
  * Roadmap, on Start date and Target date
* First milestone, if none exists:
  gh api repos/$repo/milestones -f "title=M1: name the outcome"
* The ADD_TO_PROJECT_PAT secret, if the add-to-project workflow should run:
  a classic PAT with the project scope
* Branch protection on main (public repos on the Free plan):
  require the process and ci checks before merge
* Fill the "This project" section of AGENTS.md, then clear the markers:
  grep -rn "TEMPLATE[:]" . should find nothing
EOF
