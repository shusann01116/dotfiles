#!/usr/bin/env bash
set -uo pipefail

# Interactive PR picker. Runs in a visible pane opened by pick-pr.sh, with the
# pane cwd at the repo root and PR_PICK_PANE set to this pane's id.
# Flow: gh pr list -> drop fork PRs -> fzf -> open the selected PR's head
# branch as a worktree-backed workspace (reusing a worktree that already has
# the branch checked out). Prefers `herdr worktree create` so the
# worktree.created event fires for the worktree-bootstrap plugin; falls back
# to plain git + `herdr worktree open` when create refuses the branch.

HERDR="${HERDR_BIN_PATH:-herdr}"
PANE="${PR_PICK_PANE:-}"

finish() { # $1 = exit code; close our own pane on the way out
  [ -z "$PANE" ] || "$HERDR" pane close "$PANE" >/dev/null 2>&1 || true
  exit "$1"
}

fail() { # show the error and hold the pane open until acknowledged
  echo "pr-worktree: $*" >&2
  read -r -p "Press Enter to close..." _ || true
  finish 1
}

repo=$(git rev-parse --show-toplevel 2>/dev/null) || fail "not inside a git repository"

prs=$(gh pr list --limit 50 --json number,title,headRefName,author,isCrossRepository 2>&1) \
  || fail "gh pr list failed: $prs"

# Field 1 (hidden via --with-nth) carries the bare PR number for the preview
# command and the post-selection lookup.
lines=$(printf '%s' "$prs" | jq -r \
  '.[] | select(.isCrossRepository | not)
   | "\(.number)\t#\(.number) \(.title) (\(.author.login)) [\(.headRefName)]"' 2>/dev/null || true)
[ -n "$lines" ] || fail "no open same-repo PRs"

sel=$(printf '%s\n' "$lines" | fzf --delimiter='\t' --with-nth=2.. \
  --prompt='PR> ' --preview='gh pr view {1}' --preview-window=right,60%) || true
[ -n "$sel" ] || finish 0

num=$(printf '%s' "$sel" | cut -f1)
head_ref=$(printf '%s' "$prs" | jq -r --argjson n "$num" \
  '.[] | select(.number == $n) | .headRefName')
[ -n "$head_ref" ] || fail "could not resolve head branch for PR #$num"

# Reuse a worktree that already has the branch checked out.
existing=$(git worktree list --porcelain | awk -v ref="branch refs/heads/$head_ref" '
  /^worktree /{wt=substr($0, 10)} $0 == ref {print wt; exit}')
if [ -n "$existing" ]; then
  "$HERDR" worktree open --path "$existing" --focus >/dev/null \
    || fail "herdr worktree open failed for $existing"
  finish 0
fi

git fetch origin "$head_ref" || fail "git fetch origin $head_ref failed"

if "$HERDR" worktree create --cwd "$repo" --branch "$head_ref" \
     --base "origin/$head_ref" --focus >/dev/null 2>&1; then
  finish 0
fi

# Fallback: create the worktree with git, then hand it to herdr.
wt_path="${repo}.worktrees/${head_ref//\//-}"
if git -C "$repo" show-ref --verify --quiet "refs/heads/$head_ref"; then
  git -C "$repo" worktree add "$wt_path" "$head_ref" \
    || fail "git worktree add failed for $head_ref"
else
  git -C "$repo" worktree add --track -b "$head_ref" "$wt_path" "origin/$head_ref" \
    || fail "git worktree add failed for $head_ref"
fi
"$HERDR" worktree open --path "$wt_path" --focus >/dev/null \
  || fail "herdr worktree open failed for $wt_path"
finish 0
