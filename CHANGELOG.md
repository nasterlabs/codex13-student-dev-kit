# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [Unreleased]

## [0.7.0-alpha.0] - 2026-05-04

First public alpha release line. Public release artifacts use
`0.7.0-alpha.<build_number>` versions and matching
`v0.7.0-alpha.<build_number>` tags.

### Added

- Bilingual installer (Polish UI; English UI when the Windows system language is
  not Polish).
- Five installation profiles: **Start** and **Classroom** (available); **Web
  Developer**, **Fullstack**, and **Custom** (planned, disabled).
- Components: VS Code, Git and XAMPP in active profiles; OpenSSH is planned and
  remains hidden from the alpha wizard.
- Portable installation — no administrator rights required, no system-wide PATH
  changes.
- Post-install manifest written to `codex13-sdk.manifest.json` in the install
  root.
- XAMPP Unicode path patch for machines with non-ASCII usernames.
- Uninstall with optional user-data preservation.
- `nasterarchive` NSIS plugin for in-process archive extraction.
- CI workflow (repository checks, commitlint, DCO sign-off, installer build).
- Release workflow with SHA-256 checksums and GitHub Release publishing.

### Known limitations

- Public alpha installer executables are unsigned until Authenticode signing is
  configured.
- Repair mode and manual component selection are planned but disabled.

[Unreleased]: https://github.com/nasterlabs/codex13-student-dev-kit/compare/v0.7.0-alpha.0...HEAD
[0.7.0-alpha.0]: https://github.com/nasterlabs/codex13-student-dev-kit/releases/tag/v0.7.0-alpha.0
