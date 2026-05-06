# Contributing

Thank you for helping improve Codex 13 Student Dev Kit.

This repository uses GitHub Flow:

1. Create a branch from `main`.
2. Make a focused change.
3. Run `task check`.
4. Open a pull request.
5. Use a Conventional Commit title for the pull request.
6. Make sure every commit is signed off.

## Commit Style

Use Conventional Commits:

```text
feat(installer): add unattended configuration detection
fix(build): validate missing NSIS plugin before makensis
docs: describe release signing requirements
```

Allowed types are `build`, `chore`, `ci`, `docs`, `feat`, `fix`, `perf`,
`refactor`, `revert`, `style`, and `test`.

## Development Setup

See `docs/development.md`.

## Pull Requests

Before opening a pull request:

- keep changes focused and reviewable,
- do not mix unrelated changes in one pull request,
- keep installer UI strings in Polish unless the product direction changes,
- keep installer UI strings consistent with the existing localization model,
- put package URLs, versions, hashes, and app metadata in `apps/setup/src/nsis/config.nsh`,
- keep build validation in `apps/setup/scripts/build.ps1`,
- do not commit downloaded archives, cache folders, payload logs, `.env`,
  `.build`, `dist`, `node_modules`, or native `bin`/`obj` output,
- preserve UTF-8 encoding in `apps/setup/src/nsis/Codex13StudentDevKit.nsi`,
- use edits that preserve encoding and line endings for NSIS files; avoid
  whole-file rewrites of `.nsi`/`.nsh` files from tools that may change bytes,
- run `task check` before requesting review.

Maintainers may ask for changes or close pull requests that are outside the
current project scope, duplicate existing work, or cannot be reviewed safely.

## Contribution Terms

This project uses Developer Certificate of Origin sign-off and an
inbound-equals-outbound contribution policy.

By contributing, you agree that your contribution is licensed under the same
license as the project: Apache License 2.0 (`Apache-2.0`).

Sign off commits with:

```bash
git commit -s
```

The sign-off certifies the Developer Certificate of Origin:

```text
https://developercertificate.org/
```
