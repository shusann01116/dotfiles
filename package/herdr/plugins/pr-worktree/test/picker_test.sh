#!/usr/bin/env bash
set -euo pipefail

# Unit test for picker.sh using fake `gh` / `fzf` / `herdr` plus a real git
# repo with a local bare origin. picker.sh runs as a popup and resolves the
# target repo from HERDR_PLUGIN_CONTEXT_JSON, so every case runs from a
# neutral cwd. Verifies:
#   A. fork PRs (isCrossRepository) are excluded from the fzf input, and the
#      selected PR leads to `herdr worktree create --branch <head> --base
#      origin/<head> --focus`
#   B. a worktree that already has the branch checked out is reused via
#      `herdr worktree open --path <wt> --focus` (no create)
#   C. when `herdr worktree create` fails, the fallback creates the worktree
#      with git at <repo>.worktrees/<branch> and opens it via `worktree open`
#   D. fzf abort (Esc) -> no worktree commands, exit 0
#   E. zero same-repo PRs -> exit 1, fzf never invoked
#   F. context cwd outside a git repo -> exit 1, gh never invoked
#   G. missing/empty plugin context -> exit 1
#   H. context cwd inside a linked worktree -> worktree actions anchor on the
#      main checkout root (herdr rejects them from a linked worktree)

HERE=$(cd "$(dirname "$0")/.." && pwd)
PICKER="$HERE/picker.sh"
# Canonicalize: macOS mktemp returns /var/... (a symlink to /private/var), but
# git reports physical paths, so all expectations must be built from the
# physical form.
TMP=$(mktemp -d)
TMP=$(cd "$TMP" && pwd -P)
trap 'rm -rf "$TMP"' EXIT

FAKE_BIN="$TMP/bin"
mkdir -p "$FAKE_BIN"

cat > "$FAKE_BIN/gh" <<'EOF'
#!/usr/bin/env bash
echo "gh $*" >> "$GH_CALLS"
if [ "$1" = "pr" ] && [ "$2" = "list" ]; then
  cat "$GH_PRS_JSON"
fi
EOF
chmod +x "$FAKE_BIN/gh"

# Fake fzf: capture stdin; abort on FZF_ABORT=1, otherwise select line 1.
cat > "$FAKE_BIN/fzf" <<'EOF'
#!/usr/bin/env bash
cat > "$FZF_INPUT"
if [ "${FZF_ABORT:-0}" = "1" ]; then
  exit 130
fi
head -n 1 "$FZF_INPUT"
EOF
chmod +x "$FAKE_BIN/fzf"

cat > "$FAKE_BIN/herdr" <<'EOF'
#!/usr/bin/env bash
echo "herdr $*" >> "$HERDR_CALLS"
if [ "$1" = "worktree" ] && [ "$2" = "create" ]; then
  exit "${HERDR_CREATE_EXIT:-0}"
fi
EOF
chmod +x "$FAKE_BIN/herdr"

# Real repo with a bare origin; branch `feature` exists only on origin so the
# fallback's `--track -b feature origin/feature` path is exercised.
ORIGIN="$TMP/origin.git"
git init -q --bare "$ORIGIN"
REPO="$TMP/repo"
git clone -q "$ORIGIN" "$REPO" 2>/dev/null
git -C "$REPO" -c user.email=t@t -c user.name=t commit -q --allow-empty -m init
git -C "$REPO" push -q origin HEAD:main
git -C "$REPO" branch feature
git -C "$REPO" push -q origin feature
git -C "$REPO" branch -D feature
REPO_REAL=$(cd "$REPO" && pwd -P)

cat > "$TMP/prs.json" <<'EOF'
[
  {"number":12,"title":"Fix picker","headRefName":"feature","author":{"login":"shusann"},"isCrossRepository":false},
  {"number":13,"title":"Fork PR","headRefName":"fork-branch","author":{"login":"someone"},"isCrossRepository":true}
]
EOF

run_picker() { # $1 = HERDR_PLUGIN_CONTEXT_JSON value (defaults to the repo)
  (
    cd "$TMP" &&
    PATH="$FAKE_BIN:$PATH" \
    HERDR_BIN_PATH="$FAKE_BIN/herdr" \
    HERDR_CALLS="$TMP/calls" \
    GH_CALLS="$TMP/gh_calls" \
    GH_PRS_JSON="$TMP/prs.json" \
    FZF_INPUT="$TMP/fzf_input" \
    HERDR_PLUGIN_CONTEXT_JSON="${1-{\"focused_pane_cwd\":\"$REPO\"}}" \
      bash "$PICKER" < /dev/null
  )
}

# Case A: fork PR filtered out; selection leads to herdr worktree create.
: > "$TMP/calls"
run_picker
if grep -q "fork-branch" "$TMP/fzf_input"; then
  echo "FAIL(A): fork PR must be excluded from the picker:" >&2
  cat "$TMP/fzf_input" >&2
  exit 1
fi
grep -q -- "worktree create --cwd $REPO_REAL --branch feature --base origin/feature --focus" "$TMP/calls" \
  || { echo "FAIL(A): herdr worktree create not issued:" >&2; cat "$TMP/calls" >&2; exit 1; }

# Case B: existing worktree for the branch is reused via worktree open.
WT="$TMP/wt-feature"
git -C "$REPO" worktree add -q --track -b feature "$WT" origin/feature
WT_REAL=$(cd "$WT" && pwd -P)
: > "$TMP/calls"
run_picker
grep -q -- "worktree open --path $WT_REAL --focus" "$TMP/calls" \
  || { echo "FAIL(B): existing worktree not reused:" >&2; cat "$TMP/calls" >&2; exit 1; }
if grep -q "worktree create" "$TMP/calls"; then
  echo "FAIL(B): worktree create must not run when a worktree exists:" >&2
  cat "$TMP/calls" >&2
  exit 1
fi
git -C "$REPO" worktree remove "$WT"
git -C "$REPO" branch -D feature

# Case C: herdr worktree create fails -> git fallback + worktree open.
: > "$TMP/calls"
HERDR_CREATE_EXIT=1 run_picker
FALLBACK="$REPO_REAL.worktrees/feature"
[ -d "$FALLBACK" ] \
  || { echo "FAIL(C): fallback worktree not created at $FALLBACK" >&2; exit 1; }
grep -q -- "worktree open --path $FALLBACK --focus" "$TMP/calls" \
  || { echo "FAIL(C): fallback worktree not opened:" >&2; cat "$TMP/calls" >&2; exit 1; }
git -C "$REPO" worktree remove "$FALLBACK"
git -C "$REPO" branch -D feature

# Case D: fzf abort -> no worktree commands, exit 0.
: > "$TMP/calls"
FZF_ABORT=1 run_picker
if grep -q "worktree" "$TMP/calls"; then
  echo "FAIL(D): no worktree command may run on fzf abort:" >&2
  cat "$TMP/calls" >&2
  exit 1
fi

# Case E: zero same-repo PRs -> exit 1, fzf never invoked.
cat > "$TMP/prs.json" <<'EOF'
[
  {"number":13,"title":"Fork PR","headRefName":"fork-branch","author":{"login":"someone"},"isCrossRepository":true}
]
EOF
: > "$TMP/calls"
rm -f "$TMP/fzf_input"
if run_picker; then
  echo "FAIL(E): picker must exit non-zero when no same-repo PR is open" >&2
  exit 1
fi
[ ! -e "$TMP/fzf_input" ] \
  || { echo "FAIL(E): fzf must not be invoked with an empty PR list" >&2; exit 1; }

# Case F: context cwd outside a git repo -> exit 1, gh never invoked.
: > "$TMP/gh_calls"
if run_picker "{\"focused_pane_cwd\":\"$TMP\"}"; then
  echo "FAIL(F): picker must exit non-zero outside a git repo" >&2
  exit 1
fi
if grep -q "pr list" "$TMP/gh_calls"; then
  echo "FAIL(F): gh must not be invoked outside a git repo" >&2
  exit 1
fi

# Case G: missing/empty plugin context -> exit 1.
if run_picker ""; then
  echo "FAIL(G): picker must exit non-zero without plugin context" >&2
  exit 1
fi

# Case H: invoked from inside a linked worktree -> anchor on the main root.
cat > "$TMP/prs.json" <<'EOF'
[
  {"number":12,"title":"Fix picker","headRefName":"feature","author":{"login":"shusann"},"isCrossRepository":false}
]
EOF
LINKED="$TMP/linked-wt"
git -C "$REPO" worktree add -q "$LINKED" main
: > "$TMP/calls"
run_picker "{\"focused_pane_cwd\":\"$LINKED\"}"
grep -q -- "worktree create --cwd $REPO_REAL --branch feature" "$TMP/calls" \
  || { echo "FAIL(H): create must anchor on the main root, not the linked worktree:" >&2; cat "$TMP/calls" >&2; exit 1; }
git -C "$REPO" worktree remove "$LINKED"

echo "PASS"
