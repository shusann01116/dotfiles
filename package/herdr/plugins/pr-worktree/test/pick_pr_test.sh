#!/usr/bin/env bash
set -euo pipefail

# Unit test for pick-pr.sh using a fake `herdr` (via HERDR_BIN_PATH).
# Verifies:
#   A. cwd outside a git repo -> graceful no-op (exit 0, no pane split)
#   B. context JSON present -> split beside the focused pane at the repo root,
#      rename the new pane to pr-pick, run picker.sh with PR_PICK_PANE set
#   C. context JSON absent -> focused pane and cwd resolved via `pane list`
#   D. context JSON supplies pane id but cwd unresolvable -> abort (exit 1, no pane split)

HERE=$(cd "$(dirname "$0")/.." && pwd)
PICK="$HERE/pick-pr.sh"
# Canonicalize: macOS mktemp returns /var/... (a symlink to /private/var), but
# git reports physical paths, so all expectations must be built from the
# physical form.
TMP=$(mktemp -d)
TMP=$(cd "$TMP" && pwd -P)
trap 'rm -rf "$TMP"' EXIT

# Fake herdr: record args; return canned JSON for `pane split` / `pane list`.
FAKE_BIN="$TMP/bin"
mkdir -p "$FAKE_BIN"
cat > "$FAKE_BIN/herdr" <<'EOF'
#!/usr/bin/env bash
echo "herdr $*" >> "$HERDR_CALLS"
if [ "$1" = "pane" ] && [ "$2" = "split" ]; then
  echo '{"result":{"pane":{"pane_id":"pane-9"},"type":"pane_split"}}'
elif [ "$1" = "pane" ] && [ "$2" = "list" ]; then
  cat "$HERDR_PANES_JSON"
fi
EOF
chmod +x "$FAKE_BIN/herdr"

REPO="$TMP/repo"
mkdir -p "$REPO"
git -C "$REPO" init -q
REPO_REAL=$(cd "$REPO" && pwd -P)

panes_json() { # $1 = cwd of the single focused pane
  printf '{"result":{"panes":[{"pane_id":"1-1","tab_id":"1:1","focused":true,"cwd":"%s"}]}}' "$1" \
    > "$TMP/panes.json"
}

run_pick() { # $1 = HERDR_PLUGIN_CONTEXT_JSON value
  HERDR_CALLS="$TMP/calls" \
  HERDR_BIN_PATH="$FAKE_BIN/herdr" \
  HERDR_PANES_JSON="$TMP/panes.json" \
  HERDR_PLUGIN_CONTEXT_JSON="$1" \
    bash "$PICK"
}

# Case A: cwd is not a git repo -> exit 0 and no pane split.
panes_json "$TMP"
: > "$TMP/calls"
run_pick "{\"focused_pane_id\":\"1-1\",\"focused_pane_cwd\":\"$TMP\"}"
if grep -q "pane split" "$TMP/calls"; then
  echo "FAIL(A): pane split must not be issued outside a git repo:" >&2
  cat "$TMP/calls" >&2
  exit 1
fi

# Case B: context JSON supplies pane id and cwd.
panes_json "$REPO"
: > "$TMP/calls"
run_pick "{\"focused_pane_id\":\"1-1\",\"focused_pane_cwd\":\"$REPO\"}"
grep -q -- "pane split 1-1 --direction right --cwd $REPO_REAL --focus" "$TMP/calls" \
  || { echo "FAIL(B): split not issued at repo root:" >&2; cat "$TMP/calls" >&2; exit 1; }
grep -q "pane rename pane-9 pr-pick" "$TMP/calls" \
  || { echo "FAIL(B): new pane not renamed to pr-pick:" >&2; cat "$TMP/calls" >&2; exit 1; }
grep -qF "pane run pane-9 PR_PICK_PANE=pane-9 bash '$HERE/picker.sh'" "$TMP/calls" \
  || { echo "FAIL(B): picker.sh not launched with PR_PICK_PANE:" >&2; cat "$TMP/calls" >&2; exit 1; }

# Case C: no context JSON -> resolve focused pane and cwd via `pane list`.
panes_json "$REPO"
: > "$TMP/calls"
run_pick ""
grep -q -- "pane split 1-1 --direction right --cwd $REPO_REAL --focus" "$TMP/calls" \
  || { echo "FAIL(C): split not issued via pane-list fallback:" >&2; cat "$TMP/calls" >&2; exit 1; }

# Case D: context JSON supplies pane id but cwd unresolvable (pane list missing cwd key) -> abort.
printf '{"result":{"panes":[{"pane_id":"1-1","tab_id":"1:1","focused":true}]}}' > "$TMP/panes.json"
: > "$TMP/calls"
if run_pick "{\"focused_pane_id\":\"1-1\"}"; then
  echo "FAIL(D): must abort when focused pane cwd cannot be resolved:" >&2
  exit 1
fi
if grep -q "pane split" "$TMP/calls"; then
  echo "FAIL(D): pane split must not be issued when cwd is unresolvable:" >&2
  cat "$TMP/calls" >&2
  exit 1
fi

echo "PASS"
