#!/usr/bin/env bash
# Sets a board field on an issue's card, adding the card first if the issue is
# not on the board yet.
#
# Usage: board.sh <issue-number> status "In progress"
#        board.sh <issue-number> estimate 3
#        board.sh <issue-number> priority P1

set -euo pipefail

[ $# -eq 3 ] || { sed -n '2,8p' "$0"; exit 1; }
issue="$1"
field="$2"
value="$3"

repo=$(gh repo view --json nameWithOwner --jq .nameWithOwner)
url=$(gh api "repos/$repo/actions/variables/PROJECT_URL" --jq .value 2>/dev/null || true)
[ -n "$url" ] || { echo "PROJECT_URL is not set on $repo; run scripts/bootstrap.sh"; exit 1; }
owner=$(sed -E 's|.*/users/([^/]+)/projects/.*|\1|' <<<"$url")
num="${url##*/}"
issue_url="https://github.com/$repo/issues/$issue"

find_item() {
  gh project item-list "$num" --owner "$owner" --limit 500 --format json \
    --jq ".items[] | select(.content.url == \"$issue_url\") | .id" | head -1
}

item_id=$(find_item)
if [ -z "$item_id" ]; then
  gh project item-add "$num" --owner "$owner" --url "$issue_url" >/dev/null
  item_id=$(find_item)
fi
[ -n "$item_id" ] || { echo "Issue #$issue has no card on project $num"; exit 1; }

case "$field" in
  status)   fname="Status" ;;
  estimate) fname="Estimate" ;;
  priority) fname="Priority" ;;
  *) echo "Unknown field '$field'; use status, estimate or priority"; exit 1 ;;
esac

project_id=$(gh project view "$num" --owner "$owner" --format json --jq .id)
field_id=$(gh project field-list "$num" --owner "$owner" --format json \
  --jq ".fields[] | select(.name == \"$fname\") | .id")
[ -n "$field_id" ] || { echo "Project $num has no $fname field; run scripts/bootstrap.sh"; exit 1; }

if [ "$field" = "estimate" ]; then
  gh project item-edit --id "$item_id" --project-id "$project_id" \
    --field-id "$field_id" --number "$value" >/dev/null
else
  option_id=$(gh project field-list "$num" --owner "$owner" --format json \
    --jq ".fields[] | select(.name == \"$fname\") | .options[] | select(.name == \"$value\") | .id")
  [ -n "$option_id" ] || { echo "$fname has no option '$value'"; exit 1; }
  gh project item-edit --id "$item_id" --project-id "$project_id" \
    --field-id "$field_id" --single-select-option-id "$option_id" >/dev/null
fi

echo "#$issue $fname -> $value"
