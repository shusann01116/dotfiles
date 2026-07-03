#!/usr/bin/env bash
set -euo pipefail

# Unit test for dispatch.sh using a fake `herdr` (via HERDR_BIN_PATH) and real
# git worktrees. The payload shape matches a real herdr 0.7.1 worktree.created
# event (nested under .data). Verifies:
#   A. no-op when neither the payload's repo_root nor git yields a .herdr/setup
#   B. primary path: repo_root from the payload resolves MAIN's .herdr/setup and
#      the setup runs in the NEW worktree (tab-create --cwd NEW, pane-run MAIN)
#   C. fallback: with repo_root absent, dispatch resolves MAIN from git for a real
#      linked worktree (main != new worktree)

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
  echo '{"result":{"root_pane":{"pane_id":"pane-123"},"type":"tab_created"}}'
fi
EOF
chmod +x "$FAKE_BIN/herdr"

# MAIN git repo.
REPO="$TMP/repo"
mkdir -p "$REPO"
git -C "$REPO" init -q
git -C "$REPO" -c user.email=t@t -c user.name=t commit -q --allow-empty -m init
REPO_REAL=$(cd "$REPO" && pwd -P)

run_dispatch() { # $1 = new worktree path, $2 = main repo_root ("" to omit)
  local ro=""
  [ -n "$2" ] && ro=$(printf '"repo_root":"%s",' "$2")
  local json
  json=$(printf '{"event":"worktree_created","data":{"workspace":{"workspace_id":"ws-1","worktree":{%s"checkout_path":"%s"}},"worktree":{"path":"%s","branch":"feature","open_workspace_id":"ws-1"}}}' "$ro" "$1" "$1")
  HERDR_CALLS="$TMP/calls" \
  HERDR_BIN_PATH="$FAKE_BIN/herdr" \
  HERDR_PLUGIN_EVENT="worktree.created" \
  HERDR_PLUGIN_EVENT_JSON="$json" \
    bash "$DISPATCH"
}

# Case A: no .herdr/setup anywhere -> no-op (zero herdr calls).
: > "$TMP/calls"
run_dispatch "$REPO" "$REPO"
if [ -s "$TMP/calls" ]; then
  echo "FAIL: expected no-op when .herdr/setup absent, got:" >&2
  cat "$TMP/calls" >&2
  exit 1
fi

# .herdr/setup exists in MAIN only (untracked -> never in a new worktree).
mkdir -p "$REPO/.herdr"
printf '#!/usr/bin/env bash\necho hi\n' > "$REPO/.herdr/setup"
chmod +x "$REPO/.herdr/setup"

# Case B: primary path — repo_root supplied in the payload.
WT="$TMP/wt"
mkdir -p "$WT"
: > "$TMP/calls"
run_dispatch "$WT" "$REPO"
grep -q "tab create --workspace ws-1 --cwd $WT --label setup" "$TMP/calls" \
  || { echo "FAIL(B): tab create not issued for the new worktree:" >&2; cat "$TMP/calls" >&2; exit 1; }
grep -qF "pane run pane-123 bash '$REPO/.herdr/setup'" "$TMP/calls" \
  || { echo "FAIL(B): pane run must target MAIN's .herdr/setup (from payload repo_root):" >&2; cat "$TMP/calls" >&2; exit 1; }

# Case C: fallback — repo_root omitted; dispatch resolves MAIN from git for a real
# linked worktree. git reports the canonical path, so compare against REPO_REAL.
WT2="$TMP/wt2"
git -C "$REPO" worktree add -q "$WT2" -b feature2
[ ! -e "$WT2/.herdr/setup" ] || { echo "FAIL(C): precondition — .herdr/setup should not be in the new worktree" >&2; exit 1; }
: > "$TMP/calls"
run_dispatch "$WT2" ""
grep -qF "pane run pane-123 bash '$REPO_REAL/.herdr/setup'" "$TMP/calls" \
  || { echo "FAIL(C): pane run must target MAIN's .herdr/setup (git fallback):" >&2; cat "$TMP/calls" >&2; exit 1; }

echo "PASS"
