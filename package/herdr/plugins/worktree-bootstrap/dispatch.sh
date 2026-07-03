#!/usr/bin/env bash
set -euo pipefail

# herdr worktree.created dispatcher (generic, global-safe).
# CWD = plugin directory. On a new worktree, if the repo's MAIN worktree has an
# executable `.herdr/setup`, open a visible "setup" tab in the new workspace and
# run it there. No-op for repos without `.herdr/setup`.
#
# The exact HERDR_PLUGIN_EVENT_JSON / `tab create --json` field names are not
# documented; the jq expressions below accept the plausible candidates. Confirm
# against a real payload via `herdr plugin log list` before relying on it.

HERDR="${HERDR_BIN_PATH:-herdr}"

payload="${HERDR_PLUGIN_EVENT_JSON:-}"
[ -n "$payload" ] || { echo "dispatch: no HERDR_PLUGIN_EVENT_JSON" >&2; exit 0; }

wt=$(printf '%s' "$payload" | jq -r '.checkout_path // .worktree.checkout_path // .path // empty')
ws=$(printf '%s' "$payload" | jq -r '.workspace_id // .open_workspace_id // .workspace.id // empty')
[ -n "$ws" ] || ws="${HERDR_WORKSPACE_ID:-}"

if [ -z "$wt" ] || [ -z "$ws" ]; then
  echo "dispatch: cannot resolve worktree ($wt) or workspace ($ws)" >&2
  exit 0
fi

main=$(git -C "$wt" worktree list | head -1 | awk '{print $1}')
setup="$main/.herdr/setup"

# global-safe guard: opt-in repos only
[ -x "$setup" ] || exit 0

echo "dispatch: bootstrapping $wt via $setup (workspace $ws)" >&2

pane=$("$HERDR" tab create --workspace "$ws" --cwd "$wt" --label setup --json \
  | jq -r '.pane_id // .focused_pane_id // .pane.id // empty')

if [ -z "$pane" ]; then
  echo "dispatch: failed to resolve setup pane id" >&2
  exit 1
fi

"$HERDR" pane run "$pane" "bash '$setup'"
