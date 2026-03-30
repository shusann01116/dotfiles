# Coordinator Flow

Detailed step-by-step flow for the coordinator session.

## Step 1: Read Context

Read the entire `openspec/changes/<change-name>/` directory:

- `proposal.md` — Background, scope, what changes
- `design.md` — Technical design, architecture, code patterns
- `tasks.md` — Task list with dependencies, files, verification commands
- `specs/*/spec.md` — Delta specifications
- `.openspec.yaml` — Change metadata

## Step 2: Determine PR Split Strategy

Analyze tasks.md dependencies and design.md technical design to decide:

- **PR granularity**: Target context separation, independent testability, ~300 line diffs as a guideline. Prioritize task boundaries over the line count guideline. Exclude test files and stories from line counts.
- **Dependency graph → Phase classification**: Group independent PRs into the same Phase. PRs that depend on others go into later Phases.
- **Per-PR metadata**: Branch name, PR title (`${semantic}(${scope}): ${日本語タイトル}`), corresponding task IDs from tasks.md.

Decide autonomously without asking the human. Log the reasoning in the session output.

## Step 3: Spawn Phase N Agents

For each PR in the current Phase:

1. Read `references/agent-prompt.md` template
2. Replace placeholders with task-specific values:
   - Extract relevant tasks from tasks.md (include `_Leverage`, `_Prompt`, `_Verification` fields verbatim)
   - Extract relevant sections from design.md (not the full document)
   - Set branch name, base branch, PR title
   - Set coordinator handle for report messages
3. Write the populated prompt to a temp file
4. Spawn the agent:

```bash
workmux add <branch-name> -b -P <prompt-file>
```

Write ALL prompt files first, THEN spawn ALL agents (per /coordinator rules).

## Step 3.5: Confirm Launch

```bash
workmux wait <handle-1> <handle-2> ... --status working --timeout 120
```

On timeout: run `workmux capture <handle>` for each failed agent, then escalate to human.

## Step 4: Wait for Completion + Receive Reports

```bash
workmux wait <handle-1> <handle-2> ... --timeout 7200
```

Agents report progress via `workmux send`. Monitor for:

- `PR-N: 完了` — Agent completed all steps successfully
- `PR-N: BLOCKED <reason>` — Agent needs help

On BLOCKED: run `workmux capture <handle>` for details, then either:

- Send instructions via `workmux send <handle> "<instructions>"`
- Escalate to human

On timeout: run `workmux capture` on all agents, escalate to human.

## Step 5: Phase Completion → Next Phase

When all agents in Phase N report `完了`:

Determine base branch for Phase N+1 agents:

- If the dependent Phase N PR has been merged into main → use `--base main`
- If the dependent Phase N PR is still a draft → use `--base <phase-n-branch>`

Return to Step 3 for the next Phase.

If some PRs are BLOCKED while others completed:

- Proceed with Phase N+1 PRs that do NOT depend on BLOCKED PRs
- BLOCKED PRs remain for human resolution

## Step 6: All Phases Complete → Human Handoff

Display a summary table of all PRs:

```
| PR | Number | Branch | CI Status | URL |
|----|--------|--------|-----------|-----|
| PR-1 | #892 | feat/... | LGTM | https://... |
| PR-2 | #893 | feat/... | LGTM | https://... |
```

All PRs should be in draft state with CI LGTM and comments minimized.

## Coordinator Responsibilities

- Analyze tasks and make PR split decisions
- Generate prompt files and spawn agents
- Receive progress reports and manage Phase transitions
- Intervene on BLOCKED agents (capture → send instructions)
- Escalate unresolvable issues to human
- **Never implement code directly** (same principle as /coordinator)
