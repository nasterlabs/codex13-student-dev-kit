# Agent Instructions

## Project Purpose

This repository is organized as a monorepo for **Codex 13 Student Dev Kit**. The current app is **Setup**, an NSIS installer that downloads and unpacks portable Visual Studio Code and XAMPP packages into:

`$LOCALAPPDATA\Codex13\StudentDevKit`

The future **Manager** app will live under `apps/manager`. Shared or separately built components live under `packages/`.

## Structure

- `apps/setup/src/nsis/` - Setup NSIS source, config, i18n, include files and RTF pages.
- `apps/setup/src/installer-scripts/` - helper PowerShell scripts embedded or used by Setup.
- `apps/setup/src/payload/` - files copied into the installed SDK.
- `apps/setup/src/patches/` - source patches applied by Setup, currently XAMPP.
- `apps/setup/assets/` - Setup-specific generated NSIS images and icons.
- `apps/setup/vendor/` - vendored binaries used by Setup, including NSIS plugins and 7-Zip.
- `apps/setup/scripts/` - Setup build wrappers.
- `packages/nsis-naster-archive/` - custom NSIS archive plug-in source package.
- `tools/scripts/` - repo-level checks and maintenance scripts.
- `tools/dev/` - local developer machine helpers.
- `dist/setup/` - generated Setup installer output.

## Build

This project uses Task as the developer task runner and `task build` is the
primary build command used by VS Code tasks and release-prep verification. On
Windows, install Task and PowerShell 7 with:

```powershell
winget install Task.Task
winget install Microsoft.PowerShell
```

Build from the repository root:

```powershell
task build
```

Fallback wrappers are available for environments where Task is not installed:

```powershell
.\apps\setup\scripts\build.cmd
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\apps\setup\scripts\build.ps1
```

`apps/setup/scripts/build.ps1` requires `NSIS_PATH` in `.env`, pointing to `makensis.exe`, for example:

```text
NSIS_PATH=C:\Tools\nsis\makensis.exe
```

The script validates the NSIS path, required config defines, and required plugins before running `makensis.exe`.

When working from WSL, edit files normally but remember the build still targets
Windows tooling. Prefer invoking Windows Task from the Windows side, or call the
Windows Task binary explicitly when available, for example:

```bash
/mnt/w/tools/task/task.EXE build
```

If Task is unavailable in that environment, use the Windows build wrapper or
PowerShell fallback from an environment where `NSIS_PATH` resolves to the
Windows `makensis.exe`.

## Plugin Variant

The installer script uses `Unicode true`, so the build currently uses `apps/setup/vendor/plugins/x86-unicode`. NSIS plugin folders describe the NSIS plugin ABI, not simply the target Windows architecture. Keep this variant unless the NSIS build mode is intentionally changed and tested.

## Change Rules

- Keep installer UI messages in Polish unless the product direction changes.
- Change URLs, pinned package versions, hashes, and app metadata in `apps/setup/src/nsis/config.nsh`, not in the main `.nsi` file.
- Keep `VSCODE_VERSION` pinned for reproducible student environments.
- Keep build and validation logic in `apps/setup/scripts/build.ps1`.
- Do not commit downloaded archives or cache folders.
- Do not update generated files in `dist/` unless the task explicitly concerns generated artifacts.
- Prefer ASCII in docs and scripts unless Polish UI text is required.
- Be careful with `apps/setup/src/nsis/Codex13StudentDevKit.nsi` encoding. It contains Polish UI strings and must stay UTF-8 for `makensis.exe /INPUTCHARSET UTF8`. Avoid rewriting the whole file with PowerShell `Get-Content`/`Set-Content`; use `apply_patch` or tools that preserve UTF-8 bytes.
- Before large installer-flow rewrites, create a checkpoint patch under `.build/checkpoints/` or another explicit handoff file.

## Agent Working Style

- Start from the current `main` branch for new work unless the task explicitly
  says to continue an existing PR branch.
- Keep PRs narrow. Separate release changes, workflow changes, documentation,
  formatting, and behavior changes unless the task explicitly asks to combine
  them.
- Prefer small, reviewable commits using Conventional Commit subjects, for
  example `fix(release): ...`, `ci: ...`, `docs: ...`, or
  `chore(powershell): ...`.
- Sign commits for DCO with `git commit -s`.
- Use the pull request template in `.github/PULL_REQUEST_TEMPLATE.md`. In
  `Verification`, check only commands that actually ran and leave intentionally
  skipped items unchecked.
- Do not rewrite repository history to hide mistakes in public branches. If a
  bad PR, failed release, or failed workflow happened, fix it forward unless the
  maintainer explicitly asks for another recovery path.
- Do not commit secrets, local env files, signing material, downloaded archives,
  caches, `.build`, `dist`, `node_modules`, or native `bin`/`obj` output.
- Treat workflow automation as production code. Prefer dry runs, explicit
  permissions, and clear failure modes over clever shortcuts.
- When updating an existing PR branch after `main` moved, rebase or rebuild the
  branch from `origin/main` when that is cleaner than resolving noisy format or
  generated-file conflicts by hand.

## Public Automation Context

- GitHub Actions use `.github/actions/setup-node-pnpm` for shared Node.js and
  pnpm setup. Keep its pinned versions aligned with `package.json`.
- The repository GitHub App is used by automation that must push tags or update
  PR branches. Do not replace that with workflow `GITHUB_TOKEN` when a pushed
  tag is expected to start another workflow.
- The automerge branch updater only handles eligible PRs and should skip cases
  it cannot update safely, including conflicts and workflow-file PRs that would
  require broader permissions.
- Required status checks are maintained in repository rulesets. When changing
  workflow job names, update the ruleset expectation as part of the same
  operational change.

## Verification Workflow

Use the smallest verification set that matches the risk of the change, but do
not skip checks silently.

Common checks:

```powershell
task check
git diff --check
```

Useful targeted checks:

```powershell
task check:repo
task check:yaml
task lint
task check:changelog
task build
```

Guidance:

- Run `task check` for most source, script, changelog, metadata, workflow, and
  documentation changes.
- Run `task build` after installer build/config/asset changes, NSIS changes, or
  changes that can affect generated installer output.
- Run `task build:brand-assets` after changing brand asset generator scripts or
  source brand graphics.
- Run `task format:ps` only for intentional PowerShell formatting changes. Keep
  format-only PRs separate from behavior changes.
- Manual installer execution is optional and should be intentional because it
  downloads external archives and modifies the user install directory.

## Release Work

- Release branches are named `release/v<semver>`, for example
  `release/v0.7.0-alpha.4`.
- Use `task release:prepare TAG=v<semver>` to create the release branch, update
  versioned files, refresh citation/archive metadata, and insert the generated
  changelog section.
- Manually edit the generated changelog section, remove temporary edit markers,
  then run `task release:conclude TAG=v<semver> OPEN_PR=1`.
- For a failed alpha release that should be superseded, use
  `task release:retry TAG=v<next-alpha> SUPERSEDE_TAG=v<failed-alpha>`. The
  goal is to move the existing changelog entry to the new alpha instead of
  duplicating a full release section.
- Do not reuse a tag that was already pushed. Inspect the failed run and choose
  whether to fix forward from the existing tag or prepare the next alpha.
- The release PR is the review boundary. Tagging happens only after the release
  PR is merged and the tag workflow validates the merged state.

## Installer Wizard Flow

Current page order in `apps/setup/src/nsis/Codex13StudentDevKit.nsi`:

1. Welcome page with Codex 13 branding.
2. Custom terms-and-privacy page (scrollable legal summary + three required checkboxes).
3. Installation directory page (warns on Program Files and Windows paths).
4. Existing-installation mode page (shown only when `Uninstall.exe` exists in `$INSTDIR`).
5. Custom profile page.
6. Custom preset page.
7. Existing-components page (shown only when VS Code or XAMPP directories exist).
8. Custom summary page.
9. MUI install-files page.
10. MUI finish page (launcher and open-install-dir actions).

## Verification

Minimum verification after build/config changes:

```powershell
task build
```

Manual installer execution is optional and should be intentional because it downloads external archives and modifies the user install directory.

## Project Contacts

- General / CoC enforcement / privacy: `support@naster.dev`
- Security vulnerabilities: `security@naster.dev`
- GitHub organisation: `nasterlabs`
- Product domain: `codex13.dev`
