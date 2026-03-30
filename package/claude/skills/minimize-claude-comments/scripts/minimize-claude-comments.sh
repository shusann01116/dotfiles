#!/usr/bin/env bash
#
# minimize-claude-comments.sh
#
# PR 上の @claude 関連コメントを一括 minimize する。
# 対象:
#   1. github-actions[bot] のコメント（ボットの応答）
#   2. 自分のコメントで @claude を含むもの（トリガーコメント）
#
# GitHub GraphQL API (minimizeComment mutation) を使用。
#
# Usage: minimize-claude-comments.sh <owner/repo> <pr-number>
#

set -euo pipefail

OWNER_REPO="${1:-}"
PR_NUMBER="${2:-}"

if [[ -z "${OWNER_REPO}" || -z "${PR_NUMBER}" ]]; then
  echo "Usage: minimize-claude-comments.sh <owner/repo> <pr-number>" >&2
  exit 1
fi

OWNER="${OWNER_REPO%%/*}"
REPO="${OWNER_REPO##*/}"

# Verify prerequisites
if ! command -v gh &>/dev/null; then
  echo "Error: gh CLI is not installed" >&2
  exit 1
fi

if ! gh auth status &>/dev/null; then
  echo "Error: gh CLI is not authenticated. Run gh auth login first." >&2
  exit 1
fi

if ! command -v jq &>/dev/null; then
  echo "Error: jq is not installed" >&2
  exit 1
fi

# Get current authenticated user
CURRENT_USER=$(gh api user --jq .login 2>/dev/null) || {
  echo "Error: Failed to get current user" >&2
  exit 1
}

# ─── Step 1: Fetch all issue comments on the PR ────────────────────────

ALL_COMMENTS="[]"
HAS_NEXT="true"
CURSOR=""

QUERY_FIRST='
query($owner: String!, $repo: String!, $number: Int!) {
  repository(owner: $owner, name: $repo) {
    pullRequest(number: $number) {
      comments(first: 100) {
        nodes { id author { login } body isMinimized }
        pageInfo { hasNextPage endCursor }
      }
    }
  }
}'

QUERY_AFTER='
query($owner: String!, $repo: String!, $number: Int!, $cursor: String!) {
  repository(owner: $owner, name: $repo) {
    pullRequest(number: $number) {
      comments(first: 100, after: $cursor) {
        nodes { id author { login } body isMinimized }
        pageInfo { hasNextPage endCursor }
      }
    }
  }
}'

while [[ "${HAS_NEXT}" == "true" ]]; do
  if [[ -z "${CURSOR}" ]]; then
    RESPONSE=$(gh api graphql \
      -F owner="${OWNER}" \
      -F repo="${REPO}" \
      -F number="${PR_NUMBER}" \
      -f query="${QUERY_FIRST}" 2>&1) || {
      echo "Error: Failed to fetch PR comments. Is PR #${PR_NUMBER} valid?" >&2
      echo "${RESPONSE}" >&2
      exit 1
    }
  else
    RESPONSE=$(gh api graphql \
      -F owner="${OWNER}" \
      -F repo="${REPO}" \
      -F number="${PR_NUMBER}" \
      -F cursor="${CURSOR}" \
      -f query="${QUERY_AFTER}" 2>&1) || {
      echo "Error: Failed to fetch PR comments (pagination)." >&2
      echo "${RESPONSE}" >&2
      exit 1
    }
  fi

  NODES=$(echo "${RESPONSE}" | jq -c '.data.repository.pullRequest.comments.nodes // []')
  HAS_NEXT=$(echo "${RESPONSE}" | jq -r '.data.repository.pullRequest.comments.pageInfo.hasNextPage')
  CURSOR=$(echo "${RESPONSE}" | jq -r '.data.repository.pullRequest.comments.pageInfo.endCursor')

  ALL_COMMENTS=$(echo "${ALL_COMMENTS}" "${NODES}" | jq -s '.[0] + .[1]')
done

# ─── Step 2: Filter target comments ────────────────────────────────────
# Target:
#   - github-actions[bot] comments (bot responses)
#   - Current user comments containing @claude (trigger comments)

FILTER=$(cat <<'JQFILTER'
def is_target($user):
  (.author.login == "github-actions") or
  (.author.login == $user and (.body | test("@claude"; "i")));
JQFILTER
)

TARGET_IDS=$(echo "${ALL_COMMENTS}" | jq -r --arg user "${CURRENT_USER}" "
  ${FILTER}
  .[] | select(is_target(\$user) and .isMinimized == false) | .id
")
ALREADY_MINIMIZED=$(echo "${ALL_COMMENTS}" | jq --arg user "${CURRENT_USER}" "
  ${FILTER}
  [.[] | select(is_target(\$user) and .isMinimized == true)] | length
")

IDS=()
while IFS= read -r id; do
  [[ -n "${id}" ]] && IDS+=("${id}")
done <<< "${TARGET_IDS}"

TARGET_COUNT=${#IDS[@]}

if [[ ${TARGET_COUNT} -eq 0 ]]; then
  if [[ ${ALREADY_MINIMIZED} -gt 0 ]]; then
    echo "No comments to minimize (${ALREADY_MINIMIZED} already minimized)"
  else
    echo "No @claude-related comments found on PR #${PR_NUMBER}"
  fi
  exit 0
fi

# ─── Step 3: Batch minimize using GraphQL aliases ──────────────────────

BATCH_SIZE=50
MINIMIZED=0
FAILED=0

for ((i = 0; i < TARGET_COUNT; i += BATCH_SIZE)); do
  BATCH_END=$((i + BATCH_SIZE))
  if [[ ${BATCH_END} -gt ${TARGET_COUNT} ]]; then
    BATCH_END=${TARGET_COUNT}
  fi

  MUTATION="mutation {"
  for ((j = i; j < BATCH_END; j++)); do
    NODE_ID="${IDS[j]}"
    MUTATION="${MUTATION}
  m${j}: minimizeComment(input: {subjectId: \"${NODE_ID}\", classifier: RESOLVED}) {
    minimizedComment { isMinimized }
  }"
  done
  MUTATION="${MUTATION}
}"

  RESULT=$(gh api graphql -f query="${MUTATION}" 2>&1) || {
    echo "Warning: Batch minimize failed for comments $((i + 1))-${BATCH_END}" >&2
    FAILED=$((FAILED + BATCH_END - i))
    continue
  }

  BATCH_SUCCESS=$(echo "${RESULT}" | jq '[to_entries[] | select(.value.minimizedComment.isMinimized == true)] | length')
  MINIMIZED=$((MINIMIZED + BATCH_SUCCESS))
done

# ─── Step 4: Report results ────────────────────────────────────────────

echo "Minimized ${MINIMIZED} comment(s) on PR #${PR_NUMBER}"

if [[ ${ALREADY_MINIMIZED} -gt 0 ]]; then
  echo "  (${ALREADY_MINIMIZED} already minimized, skipped)"
fi

if [[ ${FAILED} -gt 0 ]]; then
  echo "  (${FAILED} failed)"
  exit 1
fi

exit 0
