---
name: implement-from-plan
description: Reads an implementation plan Markdown file and implements the work by delegating to the implementer/verifier/fixer sub-agent cycle (see docs/loop-engineering.md), checking off tasks once the verifier approves. If $plan_file is not already clear from the conversation, confirm it with the user before using this skill.
argument-hint: "[plan_file]"
arguments:
  - plan_file
---

# Implement From Plan

Reads an implementation plan Markdown file (`implementation-plan-*.md`) and implements the work described in its "Task List". Actual coding and verification are delegated to the `implementer`, `verifier`, and `fixer` sub-agents, following the same protocol as `docs/loop-engineering.md` — this skill's own context never writes implementation code, it only tracks progress and gates the retry cycle. The implementation approach is assumed to already be finalized at the time the file was created, so this skill does not re-investigate requirements or reconsider the implementation approach.

## Arguments

- **$plan_file**: Path to the target plan Markdown file (1st argument)

If not clear from the conversation, confirm it with the user before starting work.

## Prerequisite

This skill is for the implementation phase. It assumes a plan created in Plan Mode is being executed in normal mode, after exiting Plan Mode. If still in Plan Mode, confirm with the user whether the plan has been reviewed and approved before proceeding.

## Orchestrator constraints

- Never write or edit implementation code yourself — always delegate to `implementer` or `fixer`.
- Never check off a task or treat the plan as implemented without a `verifier` APPROVE.
- Sub-agent calls are synchronous and sequential (`run_in_background: false`) — never parallelize the cycle, and never fabricate a sub-agent's result before it returns.

## Steps

### 1. Read the plan file

Read `$plan_file` and grasp the following.

- Source Issue (number and URL, if a `## Source Issue` section exists)
- Requirements / implementation approach / structural changes (for background understanding only — do not re-decide the approach)
- Task list (checkboxes within the `## Task List` section)
- Risks / open questions (if a `## Risks / Open Questions` section exists)

If the file doesn't exist, or no task list section is found, don't fall back by guessing — report this to the user and stop.

### 2. Check risks and open questions first

If `## Risks / Open Questions` contains unresolved items that directly relate to the tasks about to be implemented, confirm with the user before starting work. Unrelated items can be ignored and you can proceed.

### 3. Create a branch before starting implementation

Always create and check out a new branch before touching any code — never implement directly on the default branch (main/master, etc.).

```bash
git switch -c <branch-name>
```

- If already on a non-default branch that was created for this plan, this step can be skipped.
- Derive `<branch-name>` from the source Issue number/title if available (e.g. `issue-42-user-auth`); otherwise decide a concise name from the plan file's title.
- If the repository has an existing branch naming convention, follow it. If it's not clear, confirm with the user rather than guessing.

### 4. Implement via the implementer / verifier / fixer cycle

Track **verifier judgments**, not implementer runs — at most 3 verifier judgments total, matching `docs/loop-engineering.md`.

1. Call the Agent tool with `subagent_type: implementer`, `run_in_background: false`, passing the plan file's path/content. Instruct it to implement every unchecked (`- [ ]`) task, respecting phase/category grouping and dependency notes, and nothing beyond that scope (no out-of-scope feature additions or refactoring).
2. Call the Agent tool with `subagent_type: verifier`, `run_in_background: false`, to judge the implementation.
3. If **APPROVE**: go to Step 5.
4. If **REJECT**:
   - **1st REJECT**: call `implementer` again — a fresh Agent call with no memory of the prior attempt, so tell it to inspect current state itself (`git status`/`git diff`) and pass it the verifier's REJECT report. Repeat from sub-step 2.
   - **2nd consecutive REJECT**: call `fixer` instead of `implementer`, passing the last two verifier REJECT reports. Repeat from sub-step 2.
   - **3rd verifier judgment still REJECT**: stop here. Do not check off any tasks, and do not proceed to PR creation. Report to the user: the branch name, all three verifier REJECT reports, and that manual intervention is needed. Leave the branch and changes in place for inspection — do not discard them. End the skill here.

If `implementer` or `verifier` reports that the plan itself is ambiguous or incomplete (not something resolvable by inspecting the code), stop and confirm with the user rather than guessing on their behalf — the plan is assumed finalized, so this indicates something Step 2 should have caught.

### 5. Update the plan file

Once `verifier` returns APPROVE, mark every task in `$plan_file`'s task list as complete (`- [x]`) — the APPROVE already confirms the implementation covers the plan's tasks and nothing beyond them.

## After completion

Report: branch name, files changed (from the implementer/verifier reports), the number of verifier cycles used (and whether `fixer` was invoked), and the plan file's progress (checked / total tasks). If Step 4 stopped without approval, report that state per Step 4's instructions instead.