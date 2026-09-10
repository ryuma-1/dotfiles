---
name: create-pr-from-plan
description: Creates a PR for work implemented via implement-from-plan, based on the content of the implementation plan Markdown file. If $plan_file is not already clear from the conversation, confirm it with the user before using this skill.
argument-hint: "[plan_file]"
arguments:
  - plan_file
---

# Create PR From Plan

Creates a PR for the already-implemented changes via the `gh` command, based on the content of an implementation plan Markdown file (`implementation-plan-*.md`).

## Arguments

- **$plan_file**: Path to the plan Markdown file used for the implementation (1st argument)

If not clear from the conversation, confirm it with the user before starting work.

## Prerequisite

This skill is used after implementation is complete. If tasks in `$plan_file` remain unchecked (`- [ ]`), tell the user before creating the PR and confirm this is intended (only proceed if the user explicitly says it's fine to continue with incomplete tasks).

## Steps

### 1. Read the plan file

Read `$plan_file` and grasp the following.

- Source Issue (number and URL, if a `## Source Issue` section exists)
- Overview (`## Overview` section)
- Task list completion status (`- [x]` / `- [ ]`)

If the file doesn't exist, don't fall back by guessing — report this to the user and stop.

### 2. Commit and push

```bash
git status
git diff --stat
```

- If the current branch is still the default branch (main/master, etc.), stop and confirm with the user — this usually means branch creation was skipped or something went wrong upstream, not something to proceed past by guessing.
- If there are uncommitted changes, commit them: `git add -A && git commit -m "<type>: <summary> (#<issue_number>)"` (Conventional Commits, English, referencing the source Issue from `## 元Issue` if present). Invoking this skill is itself the request to ship the current diff as a PR, so no separate confirmation is needed for this commit.
- Push the branch: `git push -u origin <branch-name>`, using the current branch name.

### 3. Check for a PR template

- If `.github/pull_request_template.md` exists in the repository, use its structure as-is to write the PR body.
- If it doesn't exist, don't invent your own PR body structure — tell the user and stop.

### 4. Write the PR body

Fill in each section of the PR template with information from the plan file (overview, list of completed tasks, etc.). Don't change the template's structure or field names.

- If there's a source Issue, include a link to its number. Confirm with the user whether to use closing syntax (e.g. `Closes #<issue_number>`), or follow the repository's existing PR conventions.
- If any tasks remain unchecked, note this explicitly in the PR body.

### 5. Create the PR

```bash
gh pr create --title "<title>" --body "<PR body>"
```

- Base the title on the source Issue's title or the plan file's title, kept concise.
- If the base branch, whether to open as a draft PR, etc. aren't specified by repository convention, confirm with the user.

## After completion

After creating the PR, report its URL. There's no need to re-paste the full PR body in chat.