---
name: draft-issue
description: Create a GitHub issue for a bug, feature, refactor, or task once the content is already confirmed. Follows the matching template in .github/ISSUE_TEMPLATE/ to format the body and creates the issue via gh issue create.
argument-hint: [--type bug|feature|refactor|task] <content>
arguments:
  type:
    description: Issue type (bug/feature/refactor/task). If omitted, inferred from content.
    required: false
  content:
    description: The content to turn into an issue (symptom, feature idea, improvement proposal, etc.)
    required: true
---

# draft-issue

## Purpose
Take content the user has already identified as a problem or proposal, format it
according to the appropriate issue template, and create it as a GitHub issue.

## Assumptions
- The content to turn into an issue has already been provided by the user, or was
  settled in the conversation immediately before this skill is invoked.

## Steps

### 1. Confirm templates exist
- Check `.github/ISSUE_TEMPLATE/`
- If it doesn't exist, notify the user and stop (do not fall back to a custom format)

### 2. Determine the template type
- If `$type` is specified, use the corresponding template:
  - bug → bug_report.yml
  - feature → feature_request.yml
  - refactor → refactor.yml
  - task → task.yml
- If `$type` is not specified, infer the type from `$content`
- If the type is unclear, ask the user (do not guess and decide unilaterally)

### 3. Fill in template fields / factual investigation
Read each field of the selected template. Fill in what can be filled from `$content`
or the conversation. For fields that can't be filled yet, judge by field nature:

- **Fields based on the user's own observation or intent**
  (e.g., summary, reproduction steps, expected result, actual result, feature proposal summary)
  → Do not substitute with code investigation; ask the user if information is missing

- **Fields that can be factually investigated**
  (e.g., identifying the file/line a stack trace points to, searching for related
  existing issues/PRs, identifying affected files)
  → Investigate the code or GitHub to fill these in. However, limit this to
    confirming "location/existence" — do not proceed into root-cause analysis or
    comparing alternatives from there

  Rule of thumb: answering "what is happening here (fact)" may be investigated.
  Answering "why is it happening" or "how should it be fixed" should not be investigated.

- **Fields where judgment is unclear**
  → Attempt factual investigation first; if still unfilled, ask the user
    (do not fill in with your own guess)

### 4. Draft the issue body
- Format the body in Japanese, following the template's field structure

### 5. Create the issue
- Run `gh issue create --title "..." --body "..." --template <selected yml>`,
  or create with a body reflecting the filled fields
- Present the created issue's URL to the user

## Out of scope
- Root-cause identification, discussing fix approaches/alternatives, or considering
  concrete implementation steps (→ implement-issue's responsibility)
- Bulk-creating multiple issues (call this skill repeatedly if needed)
