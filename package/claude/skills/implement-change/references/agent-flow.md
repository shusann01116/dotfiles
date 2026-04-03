# Agent Session Flow

Each worktree agent executes the following steps in order after launch.

## 1. Context Review

Read the prompt contents. Understand the assigned tasks and design context.
Investigate existing code patterns referenced in the Leverage fields.

## 2. Implement

Use the /test-driven-development skill if available.
Follow the task steps from tasks.md. Confirm all tests pass before proceeding.

## 3. Self-Review (Required Before Push)

Run /pr-review. Loop until zero issues are reported.

Report: `workmux send <coordinator-handle> "<pr-id>: セルフレビューPASS"`

## 4. Pre-Push Validation

Run the task's `_Verification` commands plus lint for affected packages.
On failure: fix the issue, then return to step 3.

## 5. Commit, Push, Create Draft PR

Create commits following Conventional Commits (lowercase subject).
Push to remote with `-u origin HEAD`.
Create a draft PR following `.github/pull_request_template.md`.
CI review is triggered automatically on draft PR creation — do NOT post `@claude review` for the initial review.

Report: `workmux send <coordinator-handle> "<pr-id>: PR #<number> 作成"`

## 6. CI Review Response Loop

Wait for CI checks to complete, then check for review comments.

**How to wait**: Use `gh pr checks` with `--watch` in a background Bash call.
This blocks until all checks finish and returns a notification when done.

```bash
Bash(command: "gh pr checks <number> --watch --fail-level error", run_in_background: true)
```

Do NOT use `sleep` or promise to "check in N minutes" — Claude Code has no
timer primitive. Always use an event-driven wait (`--watch`).

When the background notification arrives, handle CI feedback directly
(do NOT use `/pr-review-response`):

1. Fetch review comments via `gh api repos/<owner>/<repo>/issues/<number>/comments`
2. Classify issues: Must Fix / Should Fix / Nice to Have
3. Fix Must Fix + Should Fix items
4. Run /pr-review loop (zero issues required)
5. Run pre-push validation (lint, test, build for affected packages)
6. Push changes
7. Post response comment via `gh pr comment`
8. Request re-review: `gh pr comment <number> --body '@claude review'`
9. Wait again: `gh pr checks <number> --watch --fail-level error` (background)
10. Repeat from step 1

If 3+ review rounds occur without resolution:
Report: `workmux send <coordinator-handle> "<pr-id>: BLOCKED CIレビュー3回超"`

On LGTM/Approve:
Report: `workmux send <coordinator-handle> "<pr-id>: CI LGTM"`

## 7. Minimize Comments

Run /minimize-claude-comments to fold CI review comments.

Report: `workmux send <coordinator-handle> "<pr-id>: 完了"`

Agent session ends (done status).

## Context Refresh

If this flow's details start to fade from context,
re-read the /implement-change skill to refresh the session flow and report protocol.

## Error Handling

For self-resolvable issues (test failures, lint errors): fix and continue from step 3.

For unresolvable issues:
Report: `workmux send <coordinator-handle> "<pr-id>: BLOCKED <reason>"`
Then wait for coordinator instructions via `workmux send`.
