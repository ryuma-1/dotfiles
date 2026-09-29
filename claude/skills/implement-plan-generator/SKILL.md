---
name: implement-plan-generator
description: Reads a requirement string, drafts an implementation plan with a task breakdown, and writes it out as a Markdown file in a given folder. Use when the user asks to "create an implementation plan", "list out the tasks needed", "turn these requirements into a task list", or "save the plan as an md file". If $output_dir or $requirement is not already clear from the conversation, confirm it with the user before using this skill.
argument-hint: "[output_dir] [requirement]"
arguments:
  - output_dir
  - requirement
---

# Implementation Plan Generator

Takes a free-form implementation requirement, produces an implementation plan and task list, and saves it as a Markdown file in the given folder.

## Arguments

The two named arguments declared in `arguments` are expanded from the positional arguments at invocation time into `$output_dir` / `$requirement`.

- **$output_dir**: Path to the folder where the Markdown file should be created (1st argument)
- **$requirement**: A free-form string describing the implementation requirement — feature summary, background, constraints, etc. (2nd argument)

Since `requirement` often contains spaces, quote it at invocation time (e.g. `/implement-plan-generator ./docs "Add a user authentication feature. ..."`).

If either argument is missing from the conversation, confirm it with the user before starting work.

## Steps

### 1. Understand the requirement

Read `$requirement` and organize the following. Don't guess at anything not stated — mark it clearly as "unknown" or "needs confirmation" instead.

- The goal of the implementation (what will become possible)
- What's in scope vs. out of scope
- Assumptions and constraints (tech stack, integration with existing systems, etc.)
- Open questions / things that need confirmation

### 2. Decide the implementation approach

Summarize how the implementation should proceed, scaled to the size of the requirement. If it naturally splits into multiple phases, briefly note the goal of each phase. Don't force a phase breakdown — a single phase is fine for a small requirement.

### 3. Break down the tasks

Based on the implementation approach, decompose the work down to units someone could actually act on. Each task should:

- Be at a granularity where starting and finishing it can be judged independently (not too large, not trivially small)
- Start with an actionable verb (e.g. "Implement...", "Write tests for...", "Configure...")
- Note dependencies where they exist (e.g. "※ start after Task A is complete")
- Be grouped by phase or category where relevant (e.g. Design/Backend/Frontend/Testing/Infra)

List tasks as Markdown checkboxes (`- [ ] `), so the user can check them off as they implement.

### 4. Diagram structural changes where applicable

If the requirement involves a change in structure that a diagram would make clearer — e.g. system/component architecture, data flow, folder/file structure before vs. after, or a state machine — express it as a Mermaid diagram under its own heading. Pick the Mermaid diagram type that fits the change (`graph`/`flowchart` for architecture or data flow, `classDiagram` or a tree-like `graph` for file/folder structure, `stateDiagram-v2` for state transitions, `sequenceDiagram` for interaction order). If nothing about the requirement changes structure in a way a diagram would clarify, omit this section entirely rather than forcing one.

### 5. Note risks and open questions

If there are ambiguous parts of the requirement, technical concerns, or external dependencies, list them briefly. Omit this section if there's nothing to note.

### 6. Create the Markdown file

Following the template below, create a Markdown file in `$output_dir`.

- Derive a short alphanumeric slug from the requirement for the filename: `implementation-plan-<slug>.md` (e.g. `implementation-plan-user-auth.md`). If a file with that name already exists, append a number.
- Create `$output_dir` first if it doesn't exist.
- Write the file so the user can use it directly to track implementation progress — be concise and concrete, without a wordy preamble.

## Markdown template

```markdown
# 実装計画: <要件から要約したタイトル>

## 概要
<何を実現するための実装か、2〜4行で>

## 要件
<$requirement の内容を整理して要約。原文の重要な制約は落とさない>

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

After creating the file, report the save path and briefly share the key points (e.g. number of tasks, phase structure) in 1-2 sentences. There's no need to re-paste the full file content in chat.
