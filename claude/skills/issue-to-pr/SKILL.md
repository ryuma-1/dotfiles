---
name: issue-to-pr
description: Given a GitHub Issue number (or, if omitted, the lowest-numbered open Issue), runs plan-from-issue → implement-from-plan → create-pr-from-plan as a single command, wrapping them in a Plan Mode approval gate. Use when the user says things like "take issue #42 all the way to a PR," "run the full pipeline on this issue," "do issue N end to end," or "work the oldest open issue."
argument-hint: "[issue_number] [output_dir] [user_plan]"
arguments:
  - issue_number
  - output_dir
  - user_plan
---

# Issue To PR

Chains the existing `plan-from-issue`, `implement-from-plan`, and `create-pr-from-plan` skills into a single command by invoking them via the Skill tool — this skill does not reimplement their logic. The only things it adds are the Plan Mode lifecycle (entering before planning, exiting for user approval before implementation) and stopping the chain if a later stage doesn't complete cleanly.

There is exactly one user checkpoint: approving the plan before implementation starts. Implementation and PR creation run without further pauses — `implement-from-plan` delegates its risky judgment calls to the `implementer`/`verifier`/`fixer` sub-agent cycle with an explicit stop condition, and `create-pr-from-plan` commits/pushes/creates the PR without a mid-flight confirmation (see those skills for details).

## Arguments

- **$issue_number** (optional): The target GitHub Issue number (1st argument). If omitted, Step 1 picks the lowest-numbered open Issue automatically — no need to confirm this with the user first, it's the defined behavior for this skill.
- **$output_dir** (optional, default `docs/plans`): passed through to `plan-from-issue` (2nd argument)
- **$user_plan** (optional): passed through to `plan-from-issue` (3rd argument)

## Steps

### 1. Resolve the target Issue

If `$issue_number` is already given, skip to Step 2.

Otherwise, find the lowest-numbered open Issue:

```bash
gh issue list --state open --limit 1000 --json number --jq 'min_by(.number).number'
```

- If this returns nothing (no open Issues), tell the user and stop — there's nothing to work on.
- If the command fails (`gh` not authenticated, repo not identified, etc.), report the error as-is and stop.
- Use the returned number as `$issue_number` for the rest of this skill, and state which Issue was auto-selected (number and title) before continuing.

### 2. Enter Plan Mode

Call `EnterPlanMode` if the conversation isn't already in Plan Mode.

### 3. Plan

Invoke the Skill tool with `skill: "plan-from-issue"`, `args: "$output_dir $issue_number $user_plan"`. It fetches the Issue, runs the `planner` sub-agent, and writes the plan file — note the path it reports.

### 4. Approve

Write the plan file's content as your Plan Mode plan, then call `ExitPlanMode`.

- If the user requests changes, don't edit the plan file yourself — re-invoke `plan-from-issue` (Step 3) with the requested changes folded into `$user_plan`, then repeat this step.
- Do not proceed to Step 5 without approval.

### 5. Implement

Invoke the Skill tool with `skill: "implement-from-plan"`, `args: "<plan_file>"`.

If it reports that it stopped early (3 verifier judgments without APPROVE), stop here — do not proceed to Step 6. Relay its report to the user as-is.

### 6. Create the PR

Invoke the Skill tool with `skill: "create-pr-from-plan"`, `args: "<plan_file>"`.

## After completion

Report concisely: Issue number/title, plan file path, branch name, and the PR URL — or, if Step 5 stopped early, that state instead.
