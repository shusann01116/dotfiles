#!/usr/bin/env bash
set -euo pipefail

# Unit test for dispatch.sh using a fake `herdr` (via HERDR_BIN_PATH) and a
# throwaway git repo. Verifies (A) no-op when the repo has no .herdr/setup and
# (B) the correct tab-create + pane-run commands when it does.

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

# Target git repo (acts as the new worktree).
REPO="$TMP/repo"
mkdir -p "$REPO"
git -C "$REPO" init -q
git -C "$REPO" -c user.email=t@t -c user.name=t commit -q --allow-empty -m init

payload=$(printf '{"checkout_path":"%s","workspace_id":"ws-1"}' "$REPO")

run_dispatch() {
  HERDR_CALLS="$TMP/calls" \
  HERDR_BIN_PATH="$FAKE_BIN/herdr" \
  HERDR_PLUGIN_EVENT="worktree.created" \
  HERDR_PLUGIN_EVENT_JSON="$payload" \
    bash "$DISPATCH"
}

# Case A: no .herdr/setup -> no-op (zero herdr calls).
: > "$TMP/calls"
run_dispatch
if [ -s "$TMP/calls" ]; then
  echo "FAIL: expected no-op when .herdr/setup absent, got:" >&2
  cat "$TMP/calls" >&2
  exit 1
fi

# Case B: .herdr/setup present -> tab create + pane run issued.
mkdir -p "$REPO/.herdr"
printf '#!/usr/bin/env bash\necho hi\n' > "$REPO/.herdr/setup"
chmod +x "$REPO/.herdr/setup"
: > "$TMP/calls"
run_dispatch
grep -q "tab create --workspace ws-1 --cwd $REPO --label setup --json" "$TMP/calls" \
  || { echo "FAIL: tab create not issued as expected:" >&2; cat "$TMP/calls" >&2; exit 1; }
grep -q "pane run pane-123 " "$TMP/calls" \
  || { echo "FAIL: pane run not issued:" >&2; cat "$TMP/calls" >&2; exit 1; }

echo "PASS"
