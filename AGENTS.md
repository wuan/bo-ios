# AGENTS.md

Guidance for AI coding agents working in this repository.

## Commits

Use [Conventional Commits](https://www.conventionalcommits.org/) for every commit:

```
<type>(<optional scope>): <description>

[optional body]

[optional footer(s)]
```

- **Types**: `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`, `revert`.
- Write the description in the imperative mood, lower case, with no trailing period.
- Keep the subject line at or under 72 characters.
- Mark breaking changes with `!` after the type/scope and add a `BREAKING CHANGE:` footer.

Examples:

- `feat(ios): add settings store, data model, and data pipeline`
- `fix(map): render strikes delivered by the pipeline`
- `chore: adopt conventional commits and ignore local files`
