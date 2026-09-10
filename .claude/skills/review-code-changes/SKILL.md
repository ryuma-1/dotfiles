---
name: review-code-changes
description: A skill for reviewing uncommitted changes (staged/unstaged) in a git-managed project and reporting findings directly in chat.
---

# Review Code Changes

Reviews uncommitted changes (staged + unstaged) in a git-managed project and reports the results directly in chat. **Does not modify code** (review only). If fixes are needed, wait for a separate request from the user.

## Steps

### 1. Get the diff

Run the following to determine the target scope.

```bash
git status --short
git diff HEAD
```

- If there are no changes, report this to the user and stop — do not fall back to anything else.
- `git diff HEAD` includes both staged and unstaged changes. If the user specifies "staged only," "specific files only," etc., follow that instead (`git diff --staged`, `git diff HEAD -- <path>`, etc.).
- If the directory is not under git management, or no repository is found, report this and stop as well.

### 2. Review criteria

For each changed file, check the following aspects.

- **Bugs / logic errors**: mismatches between intent and implementation, missed edge cases or null/exception handling
- **Consistency with existing code**: naming conventions, deviations from existing implementation patterns or style
- **Readability / maintainability**: unnecessary complexity, duplication, unneeded comments or dead code
- **Security**: missing input validation, hardcoded secrets, etc.
- **Performance**: clearly inefficient processing (e.g., heavy work inside loops)
- **Tests**: whether behavior-changing changes are accompanied by added/updated tests

### 3. Report (output directly in chat)

Report **in Japanese**. Group findings by file and indicate severity on a 3-level scale.

- 🔴 **Must fix**: bugs, clear errors, security issues
- 🟡 **Recommended**: better to fix, but doesn't block functionality
- ⚪ **Minor/optional**: matters of preference

For each finding, include the file name and line number (or relevant location) where possible. State the reasoning concisely, and do not present a full rewritten version of the code based on speculation about "how it should be fixed" (a brief suggested direction for the fix is fine if needed).

If there are no findings at all, don't list out files — simply report "No issues found" concisely.

## Out of scope

- Automatic code fixes/rewrites (review only).
- Commits, PR creation, and issue creation are outside the scope of this skill.