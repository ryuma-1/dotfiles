---
name: markdown-to-github-issues
description: Turn a Markdown file (spec, design doc, task list, RFC, meeting notes, etc.) into GitHub Issues via the gh CLI. Use when asked to "起票", "Issue化", "Issueを立てる/作る", "file issues from this doc", "turn this into GitHub issues", or otherwise convert a markdown document's content into one or more tracked GitHub Issues. If $file isn't already clear from the conversation, confirm the target file with the user before using this skill.
argument-hint: "[file] [remote]"
arguments:
  - file
  - remote
---

# Markdown → GitHub Issues

Convert the contents of a Markdown file into one or more GitHub Issues via the `gh` CLI. The workflow always has three phases: **read & split → confirm with the user → create**. Never skip the confirmation phase — issue creation is a real, external side effect that's tedious to undo.

`$file` is the path to the markdown file to convert. If it's empty, ask the user which file to use before doing anything else.

`$remote` is the name of the git remote to use. It's only needed when the repo has more than one remote (see step 2) — leave it blank otherwise.

## Git remotes in this repo

!`git remote -v`

## Steps

### 1. Read the input file

Read `$file` in full — don't assume you already know its contents.

### 2. Determine the target repository from git remotes

Look at the remotes listed above under "Git remotes in this repo" — don't ask the user for `owner/name` up front and don't put it in the markdown file.

- **Exactly one remote** → don't do anything here. `gh` auto-detects the repo from the sole remote when you omit `--repo` later, so there's nothing to resolve.
- **Multiple remotes, and `$remote` was given** → resolve that remote to `owner/name`:
  ```bash
  uv run ${CLAUDE_SKILL_DIR}/scripts/resolve_repo.py <remote-name>
  ```
  `uv` がインストールされていない場合はその旨を伝えて停止する（インストール手順: https://docs.astral.sh/uv/getting-started/installation/ ）。
  This handles both SSH (`git@github.com:owner/name.git`) and HTTPS (`https://github.com/owner/name.git` or `.../owner/name`) remote URL formats and prints the plain `owner/name` you'll pass as `--repo` in step 5. `gh` itself only accepts `owner/name` or a URL for `--repo`, not a bare remote name, which is why this conversion step exists.
- **Multiple remotes, and `$remote` is empty** → stop here. List the remote names for the user and ask them to re-run with a remote name. Do not guess or default to `origin` in this case — the whole point of asking is that with more than one remote, "the obvious one" isn't reliable.
- **No remotes at all, or not a git checkout** → tell the user and ask them to run this from within the target repo, or to point you at the repo's local path.

### 3. Split the content into issues

The document does **not** always become exactly one issue, and it does **not** always become "one issue per heading" either — use judgment about what makes a good, independently actionable unit of work:

- **Group, don't fragment.** A `##` section that's one sentence of context, or a handful of tightly related bullet points that only make sense together, usually belong in the *same* issue rather than being split apart just because they're under separate headings.
- **Split when work is independently completable.** If a section describes a chunk of work that someone could pick up, do, and close out on its own — separately from the other sections — it's a good candidate for its own issue.
- **Pull out shared context, don't duplicate it as an issue.** Background/overview/motivation sections usually aren't tasks themselves. Fold a short version of that context into the body of every issue it's relevant to (so each issue is understandable on its own without the reader needing the original doc open), rather than creating a standalone "Background" issue.
- **Respect existing structure as a strong hint.** Task lists (`- [ ] ...`), explicitly numbered work items, or headings that already read like issue titles ("Add rate limiting to the API") are strong signals for where the natural boundaries are. Lean on that structure rather than inventing your own.
- **When truly unsure whether to split** a section further, prefer the coarser grouping — it's easier for the user to ask you to split an issue further than to ask you to merge two you shouldn't have separated.
- **Watch for an unusually large plan.** If you're heading toward a large number of issues (say, 15+), pause and check with the user that this granularity is what they want before drafting bodies for all of them.

For each planned issue, draft:
- **Title（タイトル）** — 短く具体的に、何をする/直すのかが一目で分かるように書く（例:「/users エンドポイントにページネーションを追加」）。
- **Body（本文）** — 必ず日本語で、以下のテンプレートに沿って書く。ドキュメントに該当情報がない項目は、無理に埋めず見出しごと省略する。

  ```markdown
  ## 概要
  <何を伝えたいのか>

  ## 再現手順・背景
  <なぜこのIssueが必要か。バグなら再現手順、機能追加なら背景・動機>

  ## 期待する結果
  <どうなってほしいか>

  ## スクリーンショット・エラー出力
  <あれば貼る。なければこの見出しごと省略>

  ## タスク
  <対応すべき作業内容。チェックリスト形式(`- [ ] ...`)が使えるなら使う>

  ## 備考・関連リンク
  <関連するIssue/PRへのリンクなど。元ドキュメントの該当箇所への言及もここに書く>
  ```
- **Labels / assignees / milestone** — ドキュメント側にそのセクション向けの明示的な指定（例: 見出し直下の `Labels: bug, urgent` のような行）がある場合、または会話の中でユーザーが指示した場合にのみ付与する。根拠のないラベルを勝手に作らない。

### 4. Confirm with the user before creating anything

Present the plan as a numbered list — title plus a one-line summary of each issue's body — and ask the user to confirm, adjust, merge, split, or cancel before anything is created. Do not call `gh issue create` until the user has explicitly signed off on the plan. If the user asks for changes, revise the plan and confirm again.

### 5. Create the issues

Once approved, write the plan to a JSON file and use `scripts/create_issues.py` to create the issues via `gh`. Using the script (rather than calling `gh issue create` inline per issue) keeps behavior consistent and makes partial-failure handling reliable — if one issue fails to create (e.g. a bad label name), the script still attempts the rest and reports clearly which ones succeeded and which failed.

First, verify `gh` is installed and authenticated — if it isn't, tell the user and stop here rather than continuing. If you resolved an explicit `owner/name` in step 2 (multi-remote case), also verify that repo is reachable:

```bash
gh auth status
gh repo view <owner/name>   # only when you resolved an explicit repo in step 2
```

Then write the approved plan, e.g. to `/tmp/issues_plan.json`. Set `"repo"` to the `owner/name` you resolved in step 2, or to `null` if there was only one remote (the script then omits `--repo` and lets `gh` auto-detect):

```json
{
  "repo": "owner/name",
  "issues": [
    {
      "title": "/users エンドポイントにページネーションを追加",
      "body": "## 概要\n...\n\n## 再現手順・背景\n...\n\n## 期待する結果\n...\n\n## タスク\n- [ ] ...\n\n## 備考・関連リンク\n...",
      "labels": ["enhancement"],
      "assignees": [],
      "milestone": null
    }
  ]
}
```

Run it:

```bash
uv run ${CLAUDE_SKILL_DIR}/scripts/create_issues.py /tmp/issues_plan.json
```

The script prints, for each issue, either the created issue URL or the error it hit, and a final summary count. Report that summary back to the user, including every created issue's URL — don't just say "done."
