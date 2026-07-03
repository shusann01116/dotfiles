#!/usr/bin/env bash
set -euo pipefail

# herdr worktree.created dispatcher (generic, global-safe).
# CWD = plugin directory. On a new worktree, if the repo's MAIN worktree has an
# executable `.herdr/setup`, open a visible "setup" tab in the new workspace and
# run it there. No-op for repos without `.herdr/setup`.
#
# The exact HERDR_PLUGIN_EVENT_JSON / `tab create --json` field names are not
# documented; the jq expressions below accept the plausible candidates and fall
# back to the socket API. Confirm against a real payload via
# `herdr plugin log list` before relying on it.

HERDR="${HERDR_BIN_PATH:-herdr}"

payload="${HERDR_PLUGIN_EVENT_JSON:-}"
[ -n "$payload" ] || { echo "dispatch: no HERDR_PLUGIN_EVENT_JSON" >&2; exit 0; }

# Field names confirmed against a real payload (herdr 0.7.1): the event JSON is
# nested under .data — new worktree at .data.worktree.path, main worktree at
# .data.workspace.worktree.repo_root, workspace id at .data.workspace.workspace_id.
# Alternate keys are kept as fallbacks. jq must not abort the hook (set -e) on bad JSON.
wt=$(printf '%s' "$payload" | jq -r '.data.worktree.path // .data.workspace.worktree.checkout_path // .checkout_path // .worktree.checkout_path // .path // empty' 2>/dev/null || true)
ws=$(printf '%s' "$payload" | jq -r '.data.workspace.workspace_id // .data.worktree.open_workspace_id // .workspace_id // .open_workspace_id // empty' 2>/dev/null || true)
[ -n "$ws" ] || ws="${HERDR_WORKSPACE_ID:-}"

if [ -z "$wt" ] || [ -z "$ws" ]; then
  echo "dispatch: cannot resolve worktree ($wt) or workspace ($ws)" >&2
  exit 0
fi

# The main worktree comes straight from the payload; fall back to git if absent.
# --porcelain's first `worktree ` line is the main worktree; take the whole path
# after the prefix (no field-splitting) so paths with spaces survive.
main=$(printf '%s' "$payload" | jq -r '.data.workspace.worktree.repo_root // empty' 2>/dev/null || true)
if [ -z "$main" ]; then
  main=$(git -C "$wt" worktree list --porcelain 2>/dev/null \
    | awk '/^worktree /{sub(/^worktree /, ""); print; exit}' || true)
fi
setup="$main/.herdr/setup"

# global-safe guard: opt-in repos only
[ -x "$setup" ] || exit 0

echo "dispatch: bootstrapping $wt via $setup (workspace $ws)" >&2

# `tab create` has no --json flag; it returns JSON by default, with the new
# pane id at .result.root_pane.pane_id.
pane=$("$HERDR" tab create --workspace "$ws" --cwd "$wt" --label setup 2>/dev/null \
  | jq -r '.result.root_pane.pane_id // .root_pane.pane_id // .pane_id // empty' 2>/dev/null || true)

if [ -z "$pane" ]; then
  echo "dispatch: failed to resolve setup pane id" >&2
  exit 1
fi

# Escape embedded single quotes before wrapping the path in single quotes for the
# command string handed to `pane run` (' -> '\'').
setup_q=${setup//\'/\'\\\'\'}
"$HERDR" pane run "$pane" "bash '$setup_q'"
