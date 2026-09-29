#!/usr/bin/env bash
# Takes a project from nothing to a working board: creates the repo from the
# template, bootstraps labels, board and fields, creates milestone 1 and files
# the starting issues.
#
# Usage: new-project.sh <name> [--private] [--areas a,b,c] [--copy-from N]
#                       [--dir <parent-dir>]

set -euo pipefail

name=""
visibility="--public"
areas=""
copy_from=""
parent="$HOME/portfolio"

while [ $# -gt 0 ]; do
  case "$1" in
    --private) visibility="--private"; shift ;;
    --areas) areas="$2"; shift 2 ;;
    --copy-from) copy_from="$2"; shift 2 ;;
    --dir) parent="$2"; shift 2 ;;
    -h|--help) sed -n '2,8p' "$0"; exit 0 ;;
    *) name="$1"; shift ;;
  esac
done

[ -n "$name" ] || { sed -n '2,8p' "$0"; exit 1; }

owner=$(gh api user --jq .login)
repo="$owner/$name"
template="${TEMPLATE_REPO:-$owner/ProjectTemplate}"

cd "$parent"
gh repo create "$repo" --template "$template" "$visibility" --clone
cd "$name"

# Template generation is asynchronous, so the first clone can come up empty
for _ in $(seq 1 15); do
  [ -f AGENTS.md ] && break
  sleep 2
  git pull --quiet 2>/dev/null || true
done
[ -f AGENTS.md ] || { echo "The template content has not appeared; git pull and rerun bootstrap by hand"; exit 1; }

bootstrap_args=("$repo")
[ -n "$areas" ] && bootstrap_args+=(--areas "$areas")
[ -n "$copy_from" ] && bootstrap_args+=(--copy-from "$copy_from")
scripts/bootstrap.sh "${bootstrap_args[@]}"

echo "Milestone"
m1=$(gh api "repos/$repo/milestones" --jq '.[].title' | grep '^M1' | head -1 || true)
if [ -n "$m1" ]; then
  echo "  = milestone '$m1' exists"
else
  m1="M1: name the outcome"
  gh api "repos/$repo/milestones" -f title="$m1" \
    -f description="The first shippable outcome. Rename after the framing decision is answered." >/dev/null
  echo "  + created milestone '$m1'"
fi

# Prints the new issue's number. Arguments: title, comma-separated labels,
# body, then any extra gh issue create flags.
file_issue() {
  local title="$1" issue_labels="$2" body="$3"
  shift 3
  local issue_url
  issue_url=$(gh issue create --repo "$repo" --title "$title" \
    --label "$issue_labels" --milestone "$m1" --body "$body" "$@")
  echo "${issue_url##*/}"
}

echo "Starting backlog"
if [ "$(gh issue list --repo "$repo" --state all --limit 1 --json number --jq length)" -gt 0 ]; then
  echo "  = issues already exist; not seeding"
else
  n_frame=$(file_issue "decision: what is milestone 1's outcome?" "decision" \
"## The question

What outcome does milestone 1 deliver, and how do we know it landed?

## Options

*

## Recommendation

## Needed by

Milestone 1. The epic cannot be framed without an answer." \
    --assignee "$owner")

  n_agents=$(file_issue "docs: fill the \"This project\" section of AGENTS.md" "type:docs,area:docs" \
"## Goal

AGENTS.md tells an agent what this project is, how to build, test and run it, what the \`area:\` labels mean, and the gotchas.

## Done when

- [ ] The \"This project\" section describes this repo, not the template")

  n_ci=$(file_issue "ci: replace the placeholder check with build, lint and tests" "type:chore,area:ci" \
"## Goal

ci.yml runs this project's real checks. The house patterns in the file stay.

## Done when

- [ ] A pull request fails when the build, lint or tests fail
- [ ] release.yml packages real artifacts")

  n_readme=$(file_issue "docs: write the README" "type:docs,area:docs" \
"## Goal

The README describes this project in its own right: what it is, why it exists, how to run it.

## Done when

- [ ] The template's README is gone
- [ ] docs/roadmap.md names milestone 1's outcome and version")

  n_markers=$(file_issue "chore: clear every TEMPLATE marker" "type:chore,area:build" \
"## Goal

Every fill-in point the template left is resolved.

## Done when

- [ ] \`grep -rn \"TEMPLATE[:]\" .\` finds nothing")

  echo "  + filed #$n_frame (framing decision), #$n_agents, #$n_ci, #$n_readme, #$n_markers"

  echo "Board placement"
  scripts/board.sh "$n_frame" status "Ready"
  scripts/board.sh "$n_agents" estimate 2
  scripts/board.sh "$n_agents" status "Ready"
  scripts/board.sh "$n_ci" estimate 3
  scripts/board.sh "$n_ci" status "Backlog"
  scripts/board.sh "$n_readme" estimate 2
  scripts/board.sh "$n_readme" status "Backlog"
  scripts/board.sh "$n_markers" estimate 1
  scripts/board.sh "$n_markers" status "Backlog"
fi

cat <<EOF

$repo is ready at $parent/$name. Next:

1. Work the checklist bootstrap printed above.
2. Answer the framing decision issue, then rename milestone 1 after the outcome.
3. File the milestone 1 epic and split it into estimated, Ready sub-issues.
EOF
