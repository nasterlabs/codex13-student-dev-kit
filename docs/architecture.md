# Architecture

The repository is a monorepo for Codex 13 Student Dev Kit. The current app is
Setup, an NSIS installer for a portable student development environment. The
future Manager app will live beside it under `apps/manager`.

Setup unpacks tools under the selected install directory and starts them through
Codex 13 launchers, which set PATH and related environment variables only for
the launched process. This keeps installations independent and allows multiple
SDK copies to coexist on one computer.

## Main Areas

- `apps/setup/` - Setup application.
- `apps/setup/src/nsis/Codex13StudentDevKit.nsi` - wizard flow, sections, install,
  planned repair placeholders, and uninstall logic.
- `apps/setup/src/nsis/config.nsh` - product metadata, versions, URLs, hashes, paths, and
  size estimates.
- `apps/setup/src/nsis/i18n/` - installer UI strings and language version
  resources.
- `apps/setup/src/installer-scripts/` - helper PowerShell scripts used by the installer.
- `packages/nsis-naster-archive/` - native NSIS Unicode archive plug-in package.
- `apps/setup/scripts/build.ps1` - build validation, `makensis`, version resource setup,
  and optional signing.
- `apps/setup/src/payload/` - files copied into the installed SDK.
- `tools/scripts/` - repo-level checks and maintenance scripts.
- `tools/dev/` - local developer machine helpers.
- `assets/brand/` - shared brand source assets.

## Current Product Surface

The first public release exposes two installable profile/preset pairs:

- `start` / `clean-vscode` - installs portable Visual Studio Code.
- `classroom` / `php-mysql-classroom` - installs portable Visual Studio Code,
  portable Git for Windows, and portable XAMPP.

OpenSSH, Node.js, ImageMagick, component-level selection and repair mode are
planned for later releases.

In the current alpha, profile and preset selection are the only user-facing way
to choose components. The component-selection page exists as prepared code but
is hidden until the planned Custom mode is implemented. Repair mode is also
planned and disabled: the existing-install wizard shows it as planned/disabled
and Windows uninstall metadata sets `NoRepair=1`.

## Unattended Install

Unattended mode uses `codex13-sdk.unattended.ini` next to the installer. The
parser is all-or-nothing: a complete supported answer file runs automatically,
while an incomplete or unsupported file is ignored and the normal manual wizard
is shown.

## Manifest

Setup writes `codex13-sdk.manifest.json` in the install root as a required
handoff file for the installed SDK. The manifest records the selected
profile/preset, detected installed components, shortcuts, VS Code portable data
state, launcher PATH behavior and install log path. It intentionally does not
record per-run installer flags such as forced download or unattended mode. See
`docs/setup/manifest.md` for the schema.

## Data Preservation

The installer is designed to avoid destructive changes by default. VS Code data,
XAMPP projects, databases, logs, and package cache are preserved unless the user
explicitly chooses destructive options. SSH key preservation belongs to the
planned OpenSSH component.

## Build Pipeline

The build entry point is `apps/setup/scripts/build.ps1`, invoked via `task build`
or one of the named env-file variants (`task build:dev`, `task build:prod`).

### Env File Resolution

Configuration is resolved in this order for each variable (first match wins):

1. Process environment — variables already set take precedence; CI injects them here.
2. Named env file — resolved from the `-EnvFile` parameter or `BUILD_ENV_FILE`.
   `task build:dev` passes `.env.dev`; `task build:prod` passes `.env.prod`.
3. `.env` — default for bare `task build`.

If a file is passed through the `-EnvFile` parameter and it does not exist, the
build fails. This avoids accidentally using local release or signing settings
from a different env file.

### Build Stages

1. **Env loading** — `Import-DotEnv` reads the resolved env file without
   overwriting variables that are already in the process environment.
2. **Config validation** — `config.nsh` is parsed; `BUILD_VERSION` core must
   match `APP_VERSION`; required NSIS defines are asserted to be present.
3. **Version quad** — the SemVer string is converted to a 4-part Windows
   `FILEVERSION` resource quad (`major.minor.patch.0`).
4. **NSIS compilation** — `makensis.exe` is invoked with `/INPUTCHARSET UTF8`
   and the active channel, version, and optional debug defines.
5. **Authenticode signing** — `signtool.exe` signs the output EXE when
   `SIGNING_ENABLED=1` using `SIGN_CERT_THUMBPRINT` from `CurrentUser\My`.

### C13_DEBUG_LOG Naming

The environment variable `C13_DEBUG_LOG_FILE` (user-facing, documented in
`.env.example`) is passed to the NSIS compiler as the define `C13_DBG_LOG`
(shorter internal name). Only the env var name is relevant for build
configuration; the NSIS define name is an internal detail.

## Package Sources

Package URLs and SHA256 hashes live in `apps/setup/src/nsis/config.nsh`. Keep them pinned
for reproducible classroom environments.
