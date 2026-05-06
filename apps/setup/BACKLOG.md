# Installer Backlog

This file tracks product-facing installer backlog.

## Current Baseline

- Supported install profiles shown to users:
  - `start` with `clean-vscode`: portable VS Code only,
  - `classroom` with `php-mysql-classroom`: portable VS Code, portable Git for
    Windows, and portable XAMPP.
- Planned profiles/options are visible as disabled where useful, but are not
  installable yet.
- OpenSSH is planned and not part of the current user-selectable install
  surface.
- Manifest file name: `codex13-sdk.manifest.json`.
- Manifest creation is required; installation should fail if the manifest cannot
  be written.
- Unattended answer file name: `codex13-sdk.unattended.ini`.
- Logs use timestamped execution lines and include manifest/unattended metadata.
- Terms page loads RTF files from `apps/setup/src/nsis/pages/` instead of long
  `LangString` values.
- Deinstall removes program files quietly and preserves user data by default.

## Before Public Release

- Manually test the full wizard on a disposable install root:
  - clean `start` install,
  - clean `classroom` install,
  - uninstall with default preserved data,
  - reinstall after preserved-data-only uninstall,
  - unattended visible mode,
  - unattended `/unattended-silent` mode,
  - broken unattended file fallback to normal wizard.
- Review visible UI layout after the RTF terms change, especially on Polish text.
- Review `apps/setup/src/nsis/Codex13StudentDevKit.nsi` for variables added during the
  setup-flow refit that are declared but not yet meaningful.
- Confirm exit codes from a real Windows shell:
  - `0` success,
  - `1` install failure,
  - `2` user cancellation.
- Decide whether `forceDownload` belongs in the unattended file only, on the
  summary page only, or both.
- Review whether repair mode should stay visible as planned/disabled or be
  hidden until it is fully implemented.

## Profiles And Presets

- Rework profile semantics before broad public promotion. `Web`, `Fullstack`
  and `Custom` are currently planned/disabled, while the real first-release
  paths are `start` and `classroom`.
- Decide the actual classroom policy:
  - offline-first package usage,
  - stricter cache/hash validation,
  - fixed install root support,
  - forced shortcuts,
  - preserving VS Code/XAMPP data by default,
  - classroom-specific VS Code starter settings.
- Move profile definitions toward a data-driven shape with explicit component,
  shortcut, VS Code, cache, reinstall, and preserved-data policies.

## Unattended Install

- Current first pass is intentionally all-or-nothing:
  - accepts only complete `codex13-sdk.unattended.ini`,
  - ignores incomplete or unsupported answer files and falls back to the normal
    manual wizard without applying partial answers,
  - supports `{localappdata}`, `{appdata}`, `{userprofile}`, `{desktop}`,
    `{documents}`, `{programfiles}`, `{temp}` and normal `%ENV_VAR%`
    expansion,
  - supports `start/clean-vscode` and `classroom/php-mysql-classroom`,
  - supports only choices that are also currently available in the manual
    wizard,
  - shows progress by default,
  - supports `/unattended-silent` only after a valid answer file is accepted.
- Future expansion:
  - support explicit component selections,
  - support desktop shortcut selections,
  - support existing-component policies,
  - support a dedicated validate-only/preflight mode,
  - log the fully resolved unattended configuration before download/extraction.

## Installer UX

- Improve the summary page:
  - show required space,
  - show available disk space,
  - show package cache path,
  - block install when free space is clearly insufficient.
- Revisit progress UI only after another manual pass. The current stable state
  uses `MUI_PAGE_INSTFILES`; do not hide the native progress bar as a workaround.
- Keep deinstall details quiet for bulk file removal. User-facing details should
  describe meaningful phases, not every deleted file.

## Components

- Add ImageMagick as a real component only after URL, version, SHA256, install
  path, extraction behavior, and sanity check are defined in `apps/setup/src/nsis/config.nsh`.
- Add Node.js only after its package policy and preserved user data strategy are
  clear.
- Expand repair validation so it checks manifest, component control files,
  launcher scripts, legal/log directories, Start Menu shortcuts and desktop
  shortcuts consistently.
- Improve uninstall preflight by checking whether VS Code, XAMPP, Apache or
  MySQL processes are running before deleting files.
- Decide whether XAMPP user data should eventually move outside `tools\xampp`
  before release 1.0.

## Keep In Mind

- Do not patch final installer bytes after `makensis`; it breaks NSIS CRC.
- Do not use ZipDLL without a deliberate legal and technical decision.
- Do not hide `$mui.InstFilesPage.ProgressBar` as a progress workaround.
- Preserve UTF-8 in `apps/setup/src/nsis/Codex13StudentDevKit.nsi`; do not rewrite the
  whole file with PowerShell text commands.
