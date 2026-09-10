---
name: plan-from-issue
description: Given a GitHub Issue number, fetches the Issue via the `gh` CLI, delegates the planning judgment to the `planner` sub-agent, and generates an implementation plan with a task breakdown as a Markdown file. Optionally accepts the user's own draft plan, which is passed to `planner` as the basis for the approach. Use when the user says things like "make a plan from this issue number," "create an implementation plan for #42," or "turn this issue into a plan." If $output_dir or $issue_number is not already clear from the conversation, confirm it with the user before using this skill.
argument-hint: "[output_dir] [issue_number] [user_plan]"
arguments:
  - output_dir
  - issue_number
  - user_plan
---

# Plan From Issue

Takes a GitHub Issue number, fetches the Issue body via the `gh` CLI, delegates the planning judgment (organizing the Issue, deciding the implementation approach, breaking down tasks) to the `planner` sub-agent, and saves the resulting implementation plan and task list as a Markdown file in `$output_dir`. If the user supplies their own draft plan via `$user_plan`, it's passed to `planner` as the basis for the implementation approach, subject to `planner`'s validation against the Issue.

This skill's own context never decides the plan's content itself — that's always `planner`'s judgment. This keeps planning reviewable by a fresh sub-agent context and keeps the main conversation free of investigation detail.

## Arguments

- **$output_dir**: Path to the folder where the plan Markdown file should be created (1st argument)
- **$issue_number**: The target GitHub Issue number (2nd argument; either `#42`-style or a plain number is fine)
- **$user_plan** (optional): The user's own draft implementation approach/plan, as free-form text (3rd argument). If omitted, the implementation approach is decided from the Issue content alone.

If `$output_dir` or `$issue_number` is not clear from the conversation, confirm it with the user before starting work.

## Prerequisite

This skill is for Plan Mode only. If not currently in Plan Mode, do not proceed to fetching the Issue or creating files — tell the user so and stop (e.g. "Please run this in Plan Mode"). Don't fall back to Plan-Mode-like behavior by assumption.

## Steps

### 1. Fetch the Issue

```bash
gh issue view $issue_number --json number,title,body,url,labels,assignees,state
```

- If the command fails (Issue doesn't exist, repository not identified, `gh` not authenticated, etc.), don't fall back by guessing — report the error as-is to the user and stop.
- If the Issue is already closed (`state: CLOSED`), it's fine to continue creating the plan, but note this briefly in the final report.
- If the Issue body alone isn't enough to determine the implementation approach, you may fetch additional context (don't over-fetch):
  ```bash
  gh issue view $issue_number --comments
  ```

### 2. Delegate planning to the `planner` sub-agent

Call the Agent tool with `subagent_type: planner`, `run_in_background: false` (the plan file can't be written until this returns, so never background it). `planner` has no memory of this conversation and cannot ask follow-up questions, so the prompt must be self-contained. Include:

- The Issue's number, title, body, URL, and labels from Step 1
- Any additional context fetched via `gh issue view $issue_number --comments`, if the body alone wasn't enough to determine scope (don't over-fetch)
- `$user_plan`, if provided, with an explicit instruction: validate it against the Issue (technically feasible? consistent with the Issue's scope and requirements? nothing critical to the Issue's goal omitted?) and flag problems in its response rather than silently adopting or silently rewriting it

`planner`'s output already follows the required Markdown structure (overview, requirements, approach, structural-change diagram, task list, risks/open questions) — its judgment on organizing the Issue, deciding the approach, breaking down tasks, and whether a diagram or risks section is warranted is authoritative. Don't second-guess or rewrite its content.

### 3. Handle `planner`'s validation of `$user_plan`

If `$user_plan` was provided and `planner` flagged problems with it (contradicts the Issue's scope, technically infeasible, missing a critical step, security/architecture concerns, etc.), don't silently adopt `planner`'s replacement. Explain the concern and the alternative to the user, and wait for their decision before continuing to Step 4. If `planner` found no problems, or `$user_plan` wasn't provided, continue directly.

### 4. Create the Markdown file

Write `planner`'s output verbatim (adjusted only if Step 3 changed the outcome) as a Markdown file in `$output_dir`. Its structure matches the template below, and its content is already in Japanese as required — don't rewrite or re-summarize it.

- Filename: `implementation-plan-issue-<issue_number>-<slug>.md`. `<slug>` is a short alphanumeric slug derived from the Issue title. If a file with that name already exists, append a number.
- Create `$output_dir` first if it doesn't exist.

## Markdown template (for reference — this is `planner`'s expected output shape)

```markdown
# 実装計画: <Issueタイトルから要約したタイトル>

## 元Issue
- #<issue_number>: <title>
- <url>

## 概要
<何を実現するための実装か、2〜4行で>

## 要件
<Issue本文の内容を整理して要約。原文の重要な制約は落とさない>

## 実装方針
<フェーズ分けや進め方の方針。1フェーズのみなら省略可>

## 構成の変化
<Mermaid図（graph / classDiagram / stateDiagram-v2 / sequenceDiagram など該当するもの）。図で表せる構成変化がない場合はセクションごと省略>

## タスク一覧
### <カテゴリ名（任意）>
- [ ] タスク1
- [ ] タスク2（※タスク1の完了後）

## リスク・確認事項
- <あれば記載。なければセクションごと省略>
```

## After completion

After creating the file, report the save path and briefly share the key points (e.g. number of tasks, phase structure, link to the source Issue, and whether `$user_plan` was adopted as-is or adjusted) in 1-2 sentences. There's no need to re-paste the full file content in chat.