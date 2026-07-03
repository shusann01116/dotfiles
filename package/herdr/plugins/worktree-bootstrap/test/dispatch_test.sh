#!/usr/bin/env bash
set -euo pipefail

# Unit test for dispatch.sh using a fake `herdr` (via HERDR_BIN_PATH) and real
# git worktrees. Verifies:
#   A. no-op when the repo has no .herdr/setup
#   B. with a real linked worktree, dispatch resolves .herdr/setup from the MAIN
#      worktree (it is untracked, so it is NOT in the new worktree) and runs it
#      via tab-create + pane-run, referencing the MAIN path.

HERE=$(cd "$(dirname "$0")/.." && pwd)
DISPATCH="$HERE/dispatch.sh"
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

# Fake herdr: record args; for `tab create --json` return a pane id.
FAKE_BIN="$TMP/bin"
mkdir -p "$FAKE_BIN"
cat > "$FAKE_BIN/herdr" <<'EOF'
#!/usr/bin/env bash
echo "herdr $*" >> "$HERDR_CALLS"
if [ "$1" = "tab" ] && [ "$2" = "create" ]; then
  echo '{"pane_id":"pane-123"}'
fi
EOF
chmod +x "$FAKE_BIN/herdr"

# MAIN git repo.
REPO="$TMP/repo"
mkdir -p "$REPO"
git -C "$REPO" init -q
git -C "$REPO" -c user.email=t@t -c user.name=t commit -q --allow-empty -m init

run_dispatch() { # $1 = checkout_path
  HERDR_CALLS="$TMP/calls" \
  HERDR_BIN_PATH="$FAKE_BIN/herdr" \
  HERDR_PLUGIN_EVENT="worktree.created" \
  HERDR_PLUGIN_EVENT_JSON="$(printf '{"checkout_path":"%s","workspace_id":"ws-1"}' "$1")" \
    bash "$DISPATCH"
}

# Case A: no .herdr/setup anywhere -> no-op (zero herdr calls).
: > "$TMP/calls"
run_dispatch "$REPO"
if [ -s "$TMP/calls" ]; then
  echo "FAIL: expected no-op when .herdr/setup absent, got:" >&2
  cat "$TMP/calls" >&2
  exit 1
fi

# Case B: .herdr/setup exists in MAIN only; drive dispatch for a real NEW worktree.
mkdir -p "$REPO/.herdr"
printf '#!/usr/bin/env bash\necho hi\n' > "$REPO/.herdr/setup"
chmod +x "$REPO/.herdr/setup"

WT="$TMP/wt"
git -C "$REPO" worktree add -q "$WT" -b feature
# .herdr/setup is untracked, so it must NOT have propagated to the new worktree.
[ ! -e "$WT/.herdr/setup" ] || { echo "FAIL: precondition — .herdr/setup should not be in the new worktree" >&2; exit 1; }

: > "$TMP/calls"
run_dispatch "$WT"

grep -q "tab create --workspace ws-1 --cwd $WT --label setup --json" "$TMP/calls" \
  || { echo "FAIL: tab create not issued for the new worktree:" >&2; cat "$TMP/calls" >&2; exit 1; }
# pane run must reference the MAIN worktree's setup path, not the new worktree's.
# `git worktree list` reports the canonical path, so compare against REPO's realpath.
REPO_REAL=$(cd "$REPO" && pwd -P)
grep -qF "pane run pane-123 bash '$REPO_REAL/.herdr/setup'" "$TMP/calls" \
  || { echo "FAIL: pane run must run MAIN's .herdr/setup:" >&2; cat "$TMP/calls" >&2; exit 1; }

echo "PASS"
