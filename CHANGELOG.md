# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

The current `0.7.x` release line is an alpha line. Public release artifacts
use `0.7.0-alpha.<build_number>` versions and matching
`v0.7.0-alpha.<build_number>` tags until the installer, signing and release
automation are stable enough for a non-alpha release.

Public alpha installer executables are unsigned until Authenticode signing is
configured.

---

<!-- New release entries go here -->

<!-- BEGIN RELEASE v0.7.0-alpha.4 -->

## 🚀 [0.7.0-alpha.4](https://github.com/nasterlabs/codex13-student-dev-kit/releases/tag/v0.7.0-alpha.4) - 2026-05-12

This alpha release is the final polish pass for the `0.7.0-alpha` line before
moving toward signed release validation. It focuses on release reliability,
public project metadata, automated pull request maintenance, clearer repository
documentation, and cleaner GitHub Release notes.

### 🌟 Highlights

- Hardens release preparation by refreshing citation and archive metadata
  automatically, then validating that public metadata stays aligned with the
  package version.
- Improves GitHub Release notes generation so manually wrapped changelog prose
  renders as clean, flowing release text.
- Reduces pull request queue maintenance with automerge branch updates,
  workflow-safe skips, and clearer pull request metadata requirements.
- Refreshes public documentation, licensing notes, agent guidance, and README
  transparency context before the next release phase.

### 🐛 Fixes

#### Ci

- Skip workflow PRs in automerge updater by [@lukaszpiotrluczak](https://github.com/lukaszpiotrluczak) in [#55](https://github.com/nasterlabs/codex13-student-dev-kit/pull/55).

- Request write token for automerge branch updates by [@lukaszpiotrluczak](https://github.com/lukaszpiotrluczak) in [#54](https://github.com/nasterlabs/codex13-student-dev-kit/pull/54).

#### Release

- Keep release notes paragraphs unwrapped by [@lukaszpiotrluczak](https://github.com/lukaszpiotrluczak) in [#57](https://github.com/nasterlabs/codex13-student-dev-kit/pull/57).

- Generate retry changelog follow-ups by [@lukaszpiotrluczak](https://github.com/lukaszpiotrluczak) in [#46](https://github.com/nasterlabs/codex13-student-dev-kit/pull/46).

- Remove duplicate release notes heading by [@lukaszpiotrluczak](https://github.com/lukaszpiotrluczak) in [#43](https://github.com/nasterlabs/codex13-student-dev-kit/pull/43).

### 📝 Documentation

#### General

- Update agent and release metadata guidance by [@lukaszpiotrluczak](https://github.com/lukaszpiotrluczak) in [#56](https://github.com/nasterlabs/codex13-student-dev-kit/pull/56).

#### License

- Document notice structure by [@lukaszpiotrluczak](https://github.com/lukaszpiotrluczak) in [#45](https://github.com/nasterlabs/codex13-student-dev-kit/pull/45).

#### Readme

- Add transparency disclaimer by [@lukaszpiotrluczak](https://github.com/lukaszpiotrluczak) in [#47](https://github.com/nasterlabs/codex13-student-dev-kit/pull/47).

### 🏗️ Build, CI and Release Automation

#### CI/CD

- Centralize Node and pnpm setup by [@lukaszpiotrluczak](https://github.com/lukaszpiotrluczak) in [#51](https://github.com/nasterlabs/codex13-student-dev-kit/pull/51).

- Use offline pnpm installs by [@lukaszpiotrluczak](https://github.com/lukaszpiotrluczak) in [#49](https://github.com/nasterlabs/codex13-student-dev-kit/pull/49).

- Enforce pull request template details by [@lukaszpiotrluczak](https://github.com/lukaszpiotrluczak) in [#53](https://github.com/nasterlabs/codex13-student-dev-kit/pull/53).

- Update automerge pull request branches by [@lukaszpiotrluczak](https://github.com/lukaszpiotrluczak) in [#50](https://github.com/nasterlabs/codex13-student-dev-kit/pull/50).

### 🧹 Maintenance

#### Ci

- Use official setup-task action by [@lukaszpiotrluczak](https://github.com/lukaszpiotrluczak) in [#44](https://github.com/nasterlabs/codex13-student-dev-kit/pull/44).

#### Powershell

- Format scripts by [@lukaszpiotrluczak](https://github.com/lukaszpiotrluczak) in [#48](https://github.com/nasterlabs/codex13-student-dev-kit/pull/48).

### 📦 Release Assets

- GitHub Release: [`v0.7.0-alpha.4`](https://github.com/nasterlabs/codex13-student-dev-kit/releases/tag/v0.7.0-alpha.4)

<!-- END RELEASE v0.7.0-alpha.4 -->

<!-- BEGIN RELEASE v0.7.0-alpha.3 -->

## 🚀 [0.7.0-alpha.3](https://github.com/nasterlabs/codex13-student-dev-kit/releases/tag/v0.7.0-alpha.3) - 2026-05-11

This alpha release establishes the first public release baseline for Codex 13
Student Dev Kit. It focuses on making the Setup installer releasable through
GitHub Actions, tightening repository validation, and preparing signed,
versioned release artifacts with clear changelog and metadata output.

### 🌟 Highlights

- Introduces the first release pipeline for the Windows Setup installer,
  including version validation, artifact labeling, release metadata, and GitHub
  Release output.
- Hardens repository quality gates with CodeQL, signed commit checks, DCO
  validation, pull request metadata linting, and stricter dependency update
  validation.
- Updates the GitHub Actions and developer tooling stack used to build,
  validate, and publish release candidates.

### ✨ Features

#### Release

- Automate release preparation and notes by [@lukaszpiotrluczak](https://github.com/lukaszpiotrluczak) in [#29](https://github.com/nasterlabs/codex13-student-dev-kit/pull/29).

#### Setup

- Bootstrap signed SDK installer release pipeline by [@lukaszpiotrluczak](https://github.com/lukaszpiotrluczak) in [b59c421](https://github.com/nasterlabs/codex13-student-dev-kit/commit/b59c42112f8bbba46ee6c4949e0e7f62490e0330).

### 🐛 Fixes

#### Changelog

- Preserve generated release text by Łukasz Piotr Łuczak in [51291f8](https://github.com/nasterlabs/codex13-student-dev-kit/commit/51291f80caaaaf6d615a378de81b6ff959d0845f).

#### Ci

- Skip bot PR title lint by [@lukaszpiotrluczak](https://github.com/lukaszpiotrluczak) in [#33](https://github.com/nasterlabs/codex13-student-dev-kit/pull/33).

- Allow dependency bot PR metadata by [@lukaszpiotrluczak](https://github.com/lukaszpiotrluczak) in [#32](https://github.com/nasterlabs/codex13-student-dev-kit/pull/32).

### 📝 Documentation

#### Branding

- Polish project visuals by [@lukaszpiotrluczak](https://github.com/lukaszpiotrluczak) in [#31](https://github.com/nasterlabs/codex13-student-dev-kit/pull/31).

#### General

- Add release citation metadata by [@lukaszpiotrluczak](https://github.com/lukaszpiotrluczak) in [4c1ced1](https://github.com/nasterlabs/codex13-student-dev-kit/commit/4c1ced1bee349fe78a4daa28c3ba685183e6355a).

### ♻️ Refactoring

- Avoid mutating option parser loop counter by [@lukaszpiotrluczak](https://github.com/lukaszpiotrluczak) in [#18](https://github.com/nasterlabs/codex13-student-dev-kit/pull/18).

### 🏗️ Build, CI and Release Automation

#### Release Automation

- Gate release tagging on main checks by [@lukaszpiotrluczak](https://github.com/lukaszpiotrluczak) in [#41](https://github.com/nasterlabs/codex13-student-dev-kit/pull/41).

- Support failed alpha release retries by [@lukaszpiotrluczak](https://github.com/lukaszpiotrluczak) in [#39](https://github.com/nasterlabs/codex13-student-dev-kit/pull/39).

- Validate release version against app version by [@lukaszpiotrluczak](https://github.com/lukaszpiotrluczak) in [#27](https://github.com/nasterlabs/codex13-student-dev-kit/pull/27).

- Harden release workflow by [@lukaszpiotrluczak](https://github.com/lukaszpiotrluczak) in [#25](https://github.com/nasterlabs/codex13-student-dev-kit/pull/25).

- Improve release workflow run name by [@lukaszpiotrluczak](https://github.com/lukaszpiotrluczak) in [#23](https://github.com/nasterlabs/codex13-student-dev-kit/pull/23).

- Show release workflow invocation by [@lukaszpiotrluczak](https://github.com/lukaszpiotrluczak) in [#21](https://github.com/nasterlabs/codex13-student-dev-kit/pull/21).

- Fix release workflow shell by [@lukaszpiotrluczak](https://github.com/lukaszpiotrluczak) in [#19](https://github.com/nasterlabs/codex13-student-dev-kit/pull/19).

#### Developer Tooling

- Use pwsh for developer tooling by [@lukaszpiotrluczak](https://github.com/lukaszpiotrluczak) in [#20](https://github.com/nasterlabs/codex13-student-dev-kit/pull/20).

#### Repository Checks

- Harden NSIS plugin hash generation by [@lukaszpiotrluczak](https://github.com/lukaszpiotrluczak) in [#26](https://github.com/nasterlabs/codex13-student-dev-kit/pull/26).

- Lint pull request metadata by [@lukaszpiotrluczak](https://github.com/lukaszpiotrluczak) in [#24](https://github.com/nasterlabs/codex13-student-dev-kit/pull/24).

- Validate DCO sign-off author by [@lukaszpiotrluczak](https://github.com/lukaszpiotrluczak) in [#22](https://github.com/nasterlabs/codex13-student-dev-kit/pull/22).

- Build C++ during CodeQL analysis by [@lukaszpiotrluczak](https://github.com/lukaszpiotrluczak) in [#17](https://github.com/nasterlabs/codex13-student-dev-kit/pull/17).

- Verify signed commits by [@lukaszpiotrluczak](https://github.com/lukaszpiotrluczak) in [#16](https://github.com/nasterlabs/codex13-student-dev-kit/pull/16).

- Replace eclint editorconfig check by [@lukaszpiotrluczak](https://github.com/lukaszpiotrluczak) in [#15](https://github.com/nasterlabs/codex13-student-dev-kit/pull/15).

- Add CodeQL scanning workflow by [@lukaszpiotrluczak](https://github.com/lukaszpiotrluczak) in [4d81052](https://github.com/nasterlabs/codex13-student-dev-kit/commit/4d81052d0c614fadd4568ac4a2435c32aba76bd8).

- Tighten dependency update validation by [@lukaszpiotrluczak](https://github.com/lukaszpiotrluczak) in [c9bbff5](https://github.com/nasterlabs/codex13-student-dev-kit/commit/c9bbff5d3e41bdd9fa07a89008eed1e2cf33bbe2).

#### CI/CD

- Remove unsupported Dependabot cooldown by [@lukaszpiotrluczak](https://github.com/lukaszpiotrluczak) in [3e31c03](https://github.com/nasterlabs/codex13-student-dev-kit/commit/3e31c037cd06c07b4701e641e0fae7b0d55b5cb0).

- Tune Dependabot update cadence by [@lukaszpiotrluczak](https://github.com/lukaszpiotrluczak) in [5299d28](https://github.com/nasterlabs/codex13-student-dev-kit/commit/5299d28e07f9c266c10688dc505abec3a5a49b4b).

- Authenticate Task setup requests by [@lukaszpiotrluczak](https://github.com/lukaszpiotrluczak) in [9885a3b](https://github.com/nasterlabs/codex13-student-dev-kit/commit/9885a3bdc5889333aa75bac23f42af20300dc825).

### ⬆️ Dependencies

#### GitHub Actions and CI

- Updated `actions/create-github-app-token` from `2.1.1` to `3.1.1` by [@dependabot[bot]](https://github.com/apps/dependabot) in [#30](https://github.com/nasterlabs/codex13-student-dev-kit/pull/30).

- Updated `actions/checkout` from `4.3.1` to `6.0.2` by [@dependabot[bot]](https://github.com/apps/dependabot) in [#12](https://github.com/nasterlabs/codex13-student-dev-kit/pull/12).

- Updated `pnpm/action-setup` from `6.0.5` to `6.0.6` by [@dependabot[bot]](https://github.com/apps/dependabot) in [#11](https://github.com/nasterlabs/codex13-student-dev-kit/pull/11).

- Updated `actions/setup-node` from `4.4.0` to `6.4.0` by [@dependabot[bot]](https://github.com/apps/dependabot) in [#7](https://github.com/nasterlabs/codex13-student-dev-kit/pull/7).

- Updated `actions/upload-artifact` from `4.6.2` to `7.0.1` by [@dependabot[bot]](https://github.com/apps/dependabot) in [#4](https://github.com/nasterlabs/codex13-student-dev-kit/pull/4).

- Updated `softprops/action-gh-release` from `2.6.2` to `3.0.0` by [@dependabot[bot]](https://github.com/apps/dependabot) in [#6](https://github.com/nasterlabs/codex13-student-dev-kit/pull/6).

- Updated `pnpm/action-setup` from `4.3.0` to `6.0.5` by [@dependabot[bot]](https://github.com/apps/dependabot) in [#5](https://github.com/nasterlabs/codex13-student-dev-kit/pull/5).

- Updated `actions/cache` from `4.3.0` to `5.0.5` by [@dependabot[bot]](https://github.com/apps/dependabot) in [#3](https://github.com/nasterlabs/codex13-student-dev-kit/pull/3).

#### Production Dependencies

_No production dependency updates._

#### Developer Tooling

- Updated `@commitlint/config-conventional` from `20.5.3` to `21.0.0` by [@dependabot[bot]](https://github.com/apps/dependabot) in [#14](https://github.com/nasterlabs/codex13-student-dev-kit/pull/14).

- Updated `@commitlint/cli` from `20.5.3` to `21.0.0` by [@dependabot[bot]](https://github.com/apps/dependabot) in [#13](https://github.com/nasterlabs/codex13-student-dev-kit/pull/13).

- Updated `markdownlint-cli2` from `0.18.1` to `0.22.1` by [@dependabot[bot]](https://github.com/apps/dependabot) in [#8](https://github.com/nasterlabs/codex13-student-dev-kit/pull/8).

- Updated `cspell` from `8.19.4` to `10.0.0` by [@dependabot[bot]](https://github.com/apps/dependabot) in [#10](https://github.com/nasterlabs/codex13-student-dev-kit/pull/10).

- Updated `@evilmartians/lefthook` from `1.13.6` to `2.1.6` by [@dependabot[bot]](https://github.com/apps/dependabot) in [#9](https://github.com/nasterlabs/codex13-student-dev-kit/pull/9).

### 🧹 Maintenance

- Initial empty commit by [@lukaszpiotrluczak](https://github.com/lukaszpiotrluczak) in [5a412a0](https://github.com/nasterlabs/codex13-student-dev-kit/commit/5a412a01d3ce775765d4ba51921ee83151c977d7).

### 📦 Release Assets

- GitHub Release: [`v0.7.0-alpha.3`](https://github.com/nasterlabs/codex13-student-dev-kit/releases/tag/v0.7.0-alpha.3)

<!-- END RELEASE v0.7.0-alpha.3 -->
