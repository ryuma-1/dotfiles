# Global Claude Preferences

## Communication
- Explain in Japanese, write code and documentation in English
- Include before/after diffs when making changes
- For complex tasks, present a plan before implementation and proceed only after approval

## Comments
- Add a doc comment before every major structure (e.g. class, function, method, property, or the equivalent in the given language)
- Format TODOs as: // TODO(reason): description
- Place inline comments on a separate line above the code, not at the end of a line
- Use "，" and "．" instead of "、" and "。" for Japanese comments
- Write comments explaining "why", not "what"

## Git / Version Control
- Use Conventional Commits (feat:, fix:, docs:, refactor:, chore:)
- Write commit messages in English
## Error Handling

- Explain the root cause before proposing a fix
- Do not suppress errors silently

## Security
- Never hardcode secrets, API keys, or credentials
- Use environment variables for sensitive configuration

## Prohibited
- Do not generate or modify README/documentation without permission
- Do not delete or comment out test code without confirmation
- Do not refactor existing working code without reason
- Do not introduce new dependencies without explicit approval

