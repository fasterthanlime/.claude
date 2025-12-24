---
name: gh-cli
description: GitHub CLI workflows for issue management, PR creation, and repository operations. Use when creating issues, opening PRs, checking CI status, managing branches, or when the user says "tackle #XXX" or "open a PR".
---

# GitHub CLI Workflows

This skill provides procedures for GitHub operations using the `gh` CLI.

## Determining the Target Repository

When filing an issue or opening a PR, determine the correct repository:

### Common bearcove repositories

- `bearcove/picante`, `bearcove/rapace`, `bearcove/arborium`
- `bearcove/dodeca`, `bearcove/vixen`, `bearcove/hindsight`, `bearcove/strid`

### External repositories

- `facet-rs/facet` (not bearcove!)

### When uncertain about the repository

1. Identify the relevant crate name from context
2. Find the crate in `Cargo.toml` or `Cargo.lock`
3. Look up the crate on crates.io: `gh api "https://crates.io/api/v1/crates/{crate_name}" --jq '.crate.repository'`
4. If the repository URL is on GitHub, use that as the target

## Tackling Issues

When the user says **"tackle #XXX"** or **"work on issue #XXX"**:

1. Fetch the issue details:
   ```bash
   gh issue view XXX
   ```
2. Read and understand the issue requirements
3. Create a feature branch (see branching rules below)
4. Implement the fix/feature
5. Remember the issue number for the eventual PR

## Creating Issues

Always use `--body-file` to avoid shell escaping problems:

```bash
# Write body to a temp file first
cat > /tmp/issue-body.md << 'EOF'
## Description
[description here]

## Steps to Reproduce
1. ...

## Expected Behavior
...
EOF

# Create the issue
gh issue create --title "Brief description" --body-file /tmp/issue-body.md
```

## Branching Rules

**Never commit directly to the main branch.**

1. Create a descriptive branch before making changes:
   ```bash
   git checkout -b feature/short-description
   # or
   git checkout -b fix/issue-XXX-short-description
   ```

2. Push the branch with upstream tracking:
   ```bash
   git push -u origin HEAD
   ```

## Commit Discipline

**Never amend commits.** Squashing is the user's responsibility, not Claude's.

- Amending risks data loss if the user has already referenced or pulled the commit
- Multiple small commits are fine; they can be squashed before merge
- If a commit has a mistake, create a new fixup commit instead

## Opening Pull Requests

Always use `--body-file` to avoid escaping issues:

```bash
cat > /tmp/pr-body.md << 'EOF'
## Summary
Brief description of changes.

## Changes
- Change 1
- Change 2

## Test Plan
- [ ] Tests pass
- [ ] Manual testing done

Closes #XXX
EOF

gh pr create --title "Brief description" --body-file /tmp/pr-body.md
```

### Linking Issues

If the conversation started with **"tackle #XXX"**, the PR body **must** include:
```
Closes #XXX
```
This automatically closes the issue when the PR merges.

### Never Close Issues Manually

**Do not close issues before the PR is merged.** The `Closes #XXX` syntax handles this automatically. Closing an issue prematurely creates confusion about whether the work is actually complete.

## Checking CI/PR Status

```bash
# View PR checks status
gh pr checks

# View specific PR
gh pr checks 123

# Watch checks until completion
gh pr checks --watch

# View PR details including review status
gh pr view 123

# List recent workflow runs
gh run list --limit 5

# View a specific run's logs
gh run view RUN_ID --log-failed
```

## Reviewing PRs

```bash
# View PR diff
gh pr diff 123

# List PR comments
gh api repos/{owner}/{repo}/pulls/123/comments

# Add a review comment
gh pr review 123 --comment --body "Comments here"

# Approve a PR
gh pr review 123 --approve

# Request changes
gh pr review 123 --request-changes --body-file /tmp/review.md
```

## Useful Queries

```bash
# List open issues assigned to you
gh issue list --assignee @me

# List PRs awaiting your review
gh pr list --search "review-requested:@me"

# List PRs you authored
gh pr list --author @me

# Search issues by label
gh issue list --label "bug"

# View issue/PR in browser
gh issue view XXX --web
gh pr view XXX --web
```

