#!/usr/bin/env python3
# /// script
# requires-python = ">=3.10"
# ///
"""
Resolve a git remote name to a plain "owner/name" GitHub repo identifier.

Usage:
    uv run resolve_repo.py <remote-name>

Handles common remote URL formats:
    git@github.com:owner/name.git
    ssh://git@github.com/owner/name.git
    https://github.com/owner/name.git
    https://github.com/owner/name
"""

import re
import subprocess
import sys


def main():
    if len(sys.argv) != 2:
        print("Usage: uv run resolve_repo.py <remote-name>", file=sys.stderr)
        sys.exit(1)

    remote_name = sys.argv[1]

    result = subprocess.run(
        ["git", "remote", "get-url", remote_name],
        capture_output=True, text=True,
    )
    if result.returncode != 0:
        print(
            f"Error: could not resolve remote '{remote_name}' "
            f"(are you inside a git checkout with that remote?)\n{result.stderr.strip()}",
            file=sys.stderr,
        )
        sys.exit(1)

    url = result.stdout.strip()

    patterns = [
        r"github\.com[:/](?P<repo>[^/]+/[^/]+?)(?:\.git)?$",
    ]

    for pattern in patterns:
        m = re.search(pattern, url)
        if m:
            print(m.group("repo"))
            return

    print(f"Error: could not parse a GitHub owner/name out of remote URL: {url}", file=sys.stderr)
    sys.exit(1)


if __name__ == "__main__":
    main()
