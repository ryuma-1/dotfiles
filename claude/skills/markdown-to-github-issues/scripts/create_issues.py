#!/usr/bin/env python3
# /// script
# requires-python = ">=3.10"
# ///
"""
Create GitHub issues from an approved JSON plan, via the `gh` CLI.

Usage:
    uv run create_issues.py <plan.json>

Plan format:
{
  "repo": "owner/name",   // optional: omit or set null to let gh auto-detect
                          // (only works when the checkout has a single git remote)
  "issues": [
    {
      "title": "...",
      "body": "...",
      "labels": ["optional", "labels"],
      "assignees": ["optional-username"],
      "milestone": "optional milestone title or number"
    },
    ...
  ]
}

Only "title" is required per issue. Creation continues even if an individual
issue fails, so one bad label/assignee doesn't block the rest of the batch.
"""

import json
import subprocess
import sys
import tempfile
import os


def create_issue(repo: str | None, issue: dict) -> tuple[bool, str]:
    title = issue.get("title")
    if not title:
        return False, "skipped: issue has no title"

    body = issue.get("body", "")
    labels = issue.get("labels") or []
    assignees = issue.get("assignees") or []
    milestone = issue.get("milestone")

    # Write body to a temp file so multi-line / special-character bodies
    # are passed reliably, rather than fighting shell quoting.
    with tempfile.NamedTemporaryFile(
        mode="w", suffix=".md", delete=False, encoding="utf-8"
    ) as f:
        f.write(body)
        body_path = f.name

    cmd = [
        "gh", "issue", "create",
        "--title", title,
        "--body-file", body_path,
    ]
    if repo:
        cmd += ["--repo", repo]
    for label in labels:
        cmd += ["--label", label]
    for assignee in assignees:
        cmd += ["--assignee", assignee]
    if milestone:
        cmd += ["--milestone", str(milestone)]

    try:
        result = subprocess.run(cmd, capture_output=True, text=True, timeout=60)
    finally:
        os.unlink(body_path)

    if result.returncode == 0:
        return True, result.stdout.strip()
    else:
        return False, (result.stderr or result.stdout).strip()


def main():
    if len(sys.argv) != 2:
        print("Usage: uv run create_issues.py <plan.json>", file=sys.stderr)
        sys.exit(1)

    plan_path = sys.argv[1]
    with open(plan_path, "r", encoding="utf-8") as f:
        plan = json.load(f)

    repo = plan.get("repo")  # may be None: gh will auto-detect from the sole git remote

    issues = plan.get("issues", [])
    if not issues:
        print("Error: plan.json has no issues to create.", file=sys.stderr)
        sys.exit(1)

    succeeded = []
    failed = []

    for i, issue in enumerate(issues, start=1):
        title = issue.get("title", f"(untitled #{i})")
        ok, message = create_issue(repo, issue)
        if ok:
            print(f"[{i}/{len(issues)}] OK  - {title}\n    -> {message}")
            succeeded.append((title, message))
        else:
            print(f"[{i}/{len(issues)}] FAIL - {title}\n    -> {message}")
            failed.append((title, message))

    print("\nSummary:")
    print(f"  Created: {len(succeeded)}/{len(issues)}")
    if failed:
        print(f"  Failed:  {len(failed)}")
        for title, message in failed:
            print(f"    - {title}: {message}")
        sys.exit(2)


if __name__ == "__main__":
    main()
