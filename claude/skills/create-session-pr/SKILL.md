---
name: create-session-pr
description: Creates a GitHub PR based on the changes made in the current session.
---

# Create Session PR

Creates a GitHub PR based on the work done in the current session (committed and/or uncommitted changes).

This skill does not decide the implementation approach or perform implementation work. It focuses solely on packaging changes that are already complete within the session into a PR.

## Steps

### 1. Understand the changes

- Check `git status` for any uncommitted changes (staged/unstaged/untracked).
- Check `git log <base>..HEAD` to see the commit history from the base branch (usually `main` or `master`; confirm with `gh repo view --json defaultBranchRef`) to the current branch.
- Check the actual diff with `git diff <base>...HEAD` (and `git diff` for any uncommitted changes).
- In addition to the above, use the conversation history from the session to understand the purpose and intent behind the changes — background that a diff alone can't convey.

### 2. If there are uncommitted changes

Do not commit automatically. Present the list of uncommitted files and confirm with the user which of the following to do:

- Commit these changes as well and include them in the PR
- Leave them out and create the PR from the committed changes only

Don't choose either option without explicit instruction.

### 3. Check the branch

If the current branch is the same as the base branch (`main`/`master`, etc.), a PR can't be created as-is. Don't invent a branch name as a fallback — confirm a new branch name with the user, then run `git checkout -b <branch-name>`.

If already on a working branch, proceed to the next step.

### 4. Check for a PR template

Check whether `.github/pull_request_template.md` exists.

- **If it exists**: use it as-is, without changing its structure (headings/sections), to write the PR body. Don't invent your own structure.
- **If it doesn't exist**: don't fall back to an ad-hoc structure. Report to the user that no template exists, and confirm whether to proceed (with a custom structure) before continuing.

### 5. Check for a related issue

If a corresponding GitHub issue number can be identified from the session's conversation, commit messages, or branch name, include `Closes #<number>` in the PR body. If it can't be identified, don't guess — omit it.

### 6. Push

Push the working branch to the remote with `git push -u origin <branch-name>`.

### 7. Create the PR

Create the PR using `gh pr create`.

- **Write the title and body entirely in Japanese.**
- The title should be a concise summary of the changes.
- The body should follow the template (or the custom structure confirmed with the user) from step 4, filled in with the information gathered in steps 1 and 5.
- Explicitly specify the base branch confirmed in step 3 (`--base`).

```bash
gh pr create --base <base-branch> --title "<Japanese title>" --body "<Japanese body>"
```

## After completion

Present the URL of the created PR, along with a brief report of:

- The number of commits included and the main changed files
- How the uncommitted changes from step 2 were handled
- The issue number, if `Closes #<number>` was included in step 5

No need to re-explain the changes in detail.