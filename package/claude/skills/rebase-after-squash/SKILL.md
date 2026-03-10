---
name: rebase-after-squash
description: >
  Resolve PR conflicts caused by squash-merged base branches.
  Use when a PR has conflicts because its base branch (or dependent commits)
  were squash-merged into main/target. Triggers on: "squash merge conflict",
  "rebase after squash", "base branch was squash merged", "PR conflicts from squash merge",
  or when `gh pr view` shows mergeStateStatus DIRTY after a squash merge.
---

# Rebase After Squash

Resolve PR conflicts caused by squash-merged parent commits by identifying
already-merged commits and rebasing with `--onto` to skip them.

## Workflow

### 1. Assess the situation

```bash
# Check PR conflict status
gh pr view --json baseRefName,mergeStateStatus,mergeable

# Fetch latest target branch
git fetch origin <baseRefName>

# Find the merge base (divergence point)
git merge-base HEAD origin/<baseRefName>

# List all commits on the feature branch since divergence
git log --oneline <merge-base>..HEAD
```

### 2. Identify squash-merged commits

Compare the feature branch commits with recent commits on the target branch.
Look for squash-merge commits that correspond to one or more feature branch commits.

```bash
# Check recent target branch commits for squash merges
git log --oneline origin/<baseRefName> -10
```

**Matching criteria:**
- Commit message similarity (squash merge titles often match PR titles)
- Changed files overlap
- Author and timing alignment

### 3. Rebase with --onto, skipping merged commits

Use `git rebase --onto` to replay only the unmerged commits onto the updated target.

```bash
git rebase --onto origin/<baseRefName> <last-squash-merged-commit> <current-branch>
```

- `origin/<baseRefName>`: new base (updated target branch)
- `<last-squash-merged-commit>`: the last commit on the feature branch that was already squash-merged (commits up to and including this one are skipped)
- `<current-branch>`: the branch to rebase

### 4. Verify and push

```bash
# Confirm only unmerged commits remain
git log --oneline origin/<baseRefName>..HEAD

# Check clean state
git status

# Force push (requires user confirmation)
git push --force-with-lease
```

## Conflict Resolution During Rebase

If conflicts occur during the rebase:

1. Resolve conflicts in the affected files
2. `git add <resolved-files>`
3. `git rebase --continue`

If the rebase becomes too complex, abort with `git rebase --abort`.

## Important Notes

- Always use `--force-with-lease` instead of `--force` for safer push
- Confirm with the user before force pushing
- If unsure which commits were squash-merged, compare changed files between the squash commit on target and the original commits on the feature branch
