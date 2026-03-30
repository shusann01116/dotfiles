# Agent Prompt Template

This template is used by the coordinator to generate prompt files for each worktree agent.
Replace all `<placeholder>` values with task-specific content before writing the prompt file.

---

```markdown
# <pr-id>: <pr-title>

## Coordinator Info

- coordinator handle: <coordinator-handle>
- report format: workmux send <coordinator-handle> "<pr-id>: <status>"

## Branch Info

- branch: <branch-name>
- base: <base-branch>
- PR title: <pr-title>

## Tasks

<tasks>
<!-- Paste the relevant task sections from tasks.md verbatim.
     Include _Leverage, _Prompt, _Verification fields as-is. -->

## Design Context

<design-context>
<!-- Paste relevant sections from design.md. Not the full document —
     only sections related to this PR's scope. -->

## Reference Files

<leverage-files>
<!-- List files from _Leverage fields. Use relative paths (each worktree has its own root). -->

## Context Refresh

If this prompt's content starts to fade from context,
re-read the /implement-change skill to refresh the session flow and report protocol.

## Session Flow

Execute the following steps in order.

1. **Implement**: Use /test-driven-development skill if available. Confirm all tests pass.
2. **Self-review**: Run /pr-review → loop until zero issues.
   → workmux send <coordinator-handle> "<pr-id>: セルフレビューPASS"
3. **Pre-push validation**: Run the task's \_Verification commands + lint for affected packages. On failure → fix → return to step 2.
4. **Commit, push, create draft PR**:
   Follow .github/pull_request_template.md for PR description.
   After PR creation: `gh pr comment <number> --body '@claude review'`
   → workmux send <coordinator-handle> "<pr-id>: PR #<number> 作成"
5. **CI review response loop**:
   - Wait ~5 min → check CI review comments via `gh api`
   - If issues found → fetch via `gh api`, classify (Must Fix / Should Fix / Nice to Have)
     → fix Must Fix + Should Fix
     → /pr-review loop (zero issues) → pre-push validation → push
     → post response comment → `@claude review`
     ※ If 3+ rounds → workmux send <coordinator-handle> "<pr-id>: BLOCKED CIレビュー3回超"
   - If LGTM → workmux send <coordinator-handle> "<pr-id>: CI LGTM"
6. **Run /minimize-claude-comments**
   → workmux send <coordinator-handle> "<pr-id>: 完了"
```

## Generation Rules

When populating this template, follow these rules:

1. **Self-contained**: Include all context the agent needs. Agents cannot see the coordinator's conversation.
2. **Relative paths**: Each worktree has its own root. Use relative paths for all file references.
3. **Preserve task metadata**: Copy `_Leverage`, `_Prompt`, `_Verification` fields from tasks.md verbatim.
4. **Selective design context**: Extract only the sections from design.md relevant to this PR's scope, not the full document.
