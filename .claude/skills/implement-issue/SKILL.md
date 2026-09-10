---
name: implement-issue
description: Fetches a GitHub issue, understands its requirements, and implements, tests, commits.
argument-hint: "[issue]"
arguments:
  - issue
disable-model-invocation: false
---

# GitHub Issue Implementation Skill

Read a specified GitHub issue, understand what it's asking for, and carry the work through implementation, verification, commit.

`$issue` contains the issue number (e.g. `123`) or issue URL. If nothing is provided, ask the user which issue to work on.

## Prerequisites

- `gh` CLI must be installed and authenticated for the target repository. If it isn't, tell the user and stop.
- Before starting, check `git status` for a clean working tree. If there are uncommitted changes, confirm with the user before proceeding.

## Steps

### 1. Fetch and understand the issue

- Run `gh issue view $issue --comments` to get the full issue body and all comments.
  - If a URL was given, use `gh issue view <url> --comments` instead.
- Extract:
  - The problem or request (repro steps, expected behavior, actual behavior)
  - Scope (what should change, what should explicitly NOT change)
  - Acceptance criteria (use whatever is stated in the issue/comments; if it's vague, define reasonable criteria yourself and state them clearly in the final summary)
  - Labels (bug / feature / good-first-issue, etc.) as a hint toward difficulty and approach
- If the issue references related PRs or issues, check them with `gh pr list --search` or `gh issue list --search`.

### 2. Create a branch

- Create a new branch for the work: `git checkout -b fix/issue-<number>-<short-description>` (skip if already on an appropriate branch).

### 3. Implement

- Implement according to the already-decided approach.
- Match the existing code style (indentation, naming conventions, comment language, etc.).
- Avoid unrelated refactoring — stay within the issue's scope.

### 4. Test

- Run the existing test suite using whatever the project uses (`npm test`, `pytest`, `go test ./...`, etc.).
- For bug fixes: add a regression test that fails before the fix and passes after.
- For new features: add tests covering the happy path, error cases, and edge cases.
- Run lint/type checks if configured, and resolve any warnings or errors.

### 5. Self-review

- Review `git diff` and check:
  - Does the change satisfy the issue's acceptance criteria?
  - Any leftover debug code or commented-out lines?
  - Any unrelated files touched?
- If anything is missing, go back to step 3 or 4.

## Final report

When done, summarize concisely:
- Issue number and title addressed
- Files changed
- Tests run and their results
- Branch name / commit(s)
- Any acceptance-criteria judgment calls made, or anything left unaddressed
