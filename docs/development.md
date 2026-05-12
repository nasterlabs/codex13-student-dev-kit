# Development

Codex 13 Student Dev Kit is a Windows NSIS installer project. It is not a web
app and does not have a unit-test suite yet.

The repository is structured as a monorepo. The current application is
`apps/setup`; future applications such as the Manager should be added under
`apps/`. Shared or separately built components belong under `packages/`, while
repo-level automation lives under `tools/scripts`.

## Required Tools

- Windows 10/11.
- PowerShell 7 or newer (`pwsh`).
- Git.
- Task: `winget install Task.Task`.
- Volta with Node.js and pnpm pinned by `package.json`.
- NSIS 3 with `makensis.exe`.
- Visual Studio Build Tools with C++ tools and a Windows SDK, required when
  rebuilding `nasterarchive.dll`.

Optional:

- VS Code with recommended extensions from `.vscode/extensions.json`.
- Windows SDK `signtool.exe` for local signing.

Install PowerShell 7 with:

```powershell
winget install Microsoft.PowerShell
```

## Environment

The build script loads an env file for local settings and secrets. The file is
never committed — `.env`, `.env.dev`, and `.env.prod` are all gitignored.
Only the `*.example` templates belong in git.

**Standard local setup** — copy `.env.example` to `.env` and set `NSIS_PATH`:

```text
NSIS_PATH=C:\Tools\nsis\makensis.exe
```

**Named env files** — for switching between dev and prod builds without editing
`.env`, copy the matching template and fill in your paths:

| Template | Copy to | Used by |
| --- | --- | --- |
| `.env.dev.example` | `.env.dev` | `task build:dev` |
| `.env.prod.example` | `.env.prod` | `task build:prod` |

Named build tasks pass their env file explicitly. If that file is missing, the
build fails instead of silently falling back to `.env`. You can also select a
file directly with `apps/setup/scripts/build.ps1 -EnvFile .env.dev` or by
setting `BUILD_ENV_FILE`.

`BUILD_VERSION` is optional. If it is set, its `major.minor.patch` core must
match `APP_VERSION` from `apps/setup/src/nsis/config.nsh`; for the first public alpha
line use values like `0.7.0-alpha.<build_number>`.

**CI** — set env vars directly in the CI environment (no file needed). Variables
already in the process environment take precedence over any env file.

### Debug log

The installer can write a debug trace file next to the installer EXE. It is
disabled by default and must be enabled at build time:

```text
C13_DEBUG_LOG_ENABLED=1
C13_DEBUG_LOG_FILE=$EXEDIR\c13sdk-debug.log  # optional override
```

Add these to `.env.dev` (or `.env`) before running `task build:dev`.

### Local code signing

Local signing is optional. Unsigned dev builds are the default and work with:

```text
SIGNING_ENABLED=0
```

To test Authenticode signing locally, generate and trust a self-signed
development certificate:

```powershell
task signing:dev-cert
```

Then add the generated thumbprint to `.env.dev`:

```text
SIGNING_ENABLED=1
SIGN_CERT_THUMBPRINT=<thumbprint z setup-dev-cert.ps1>
SIGN_TIMESTAMP_URL=http://timestamp.digicert.com
```

The local dev certificate stays in the Windows certificate store. Do not put a
PFX path or password in `.env.dev`.

### Variable Reference

All variables read by `apps/setup/scripts/build.ps1`. Variables already in the
process environment take precedence over any env file.

| Variable | Required | Default | Description |
| --- | --- | --- | --- |
| `NSIS_PATH` | Yes | — | Path to `makensis.exe`. |
| `BUILD_CHANNEL` | No | `dev` | Output channel: `dev` or `release`. Controls the output file name. |
| `BUILD_VERSION` | No | derived from `config.nsh` | Full SemVer string. Core must match `APP_VERSION` in `config.nsh`. |
| `BUILD_ENV_FILE` | No | `.env` | Env file path; overridable via the `-EnvFile` parameter. |
| `SIGNING_ENABLED` | No | `0` | Set to `1` to enable Authenticode signing. |
| `SIGN_CERT_THUMBPRINT` | No | — | Certificate thumbprint (cert-store signing mode; no password on CLI). |
| `SIGN_TIMESTAMP_URL` | No | `http://timestamp.digicert.com` | RFC 3161 timestamp server URL. |
| `SIGNTOOL_PATH` | No | auto-detected | Full path to `signtool.exe`; auto-detected from Windows SDK if omitted. |
| `C13_DEBUG_LOG_ENABLED` | No | `0` | Set to `1` to compile the installer with a debug trace log. |
| `C13_DEBUG_LOG_FILE` | No | `$EXEDIR\c13sdk-debug.log` | Debug log file path. Passed to NSIS as the `C13_DBG_LOG` define (shorter internal name). |

The default `SIGN_TIMESTAMP_URL` intentionally uses DigiCert's documented HTTP
RFC 3161 endpoint for Microsoft SignTool. Keep it as-is unless an alternative
timestamp endpoint has been tested with SignTool.

Do not commit signing certificates, private keys, or passwords.

## Tasks

List tasks:

```powershell
task --list
```

Install JavaScript development dependencies:

```powershell
task deps
```

The pinned versions are recorded in `package.json` and enforced by `.npmrc`.

Run repository checks:

```powershell
task check
```

Build the installer using `.env`:

```powershell
task build
```

Build using `.env.dev`:

```powershell
task build:dev
```

Build a release installer using `.env.prod`:

```powershell
task build:prod
```

`task build:release` is a backward-compatible alias for `task build:prod`.

Build the native NSIS archive plug-in:

```powershell
task build:nsis-naster-archive
```

`task build:plugin` is a backward-compatible alias for the same task.

This task delegates to `packages/nsis-naster-archive/Taskfile.yml` and copies
the resulting `nasterarchive.dll` into the Setup plug-in vendor directory.

Regenerate NSIS image assets from the source SVG files:

```powershell
task build:assets
```

The source brand assets live in `assets/brand/`. The generated installer assets
under `apps/setup/assets/nsis/` are tracked so the installer can be built without
ImageMagick. Intermediate render files under `.build/assets/` are ignored and
should not be committed.

This task requires `bash` in PATH. On Windows, Git Bash (installed with Git for
Windows) satisfies the requirement. Plain PowerShell and Command Prompt do not
include `bash`. Alternatively, run the task from a WSL shell.

## WSL Notes

Editing from WSL is fine. The actual build targets Windows tooling, so run Task
from PowerShell 7, Windows Terminal, or an environment where `NSIS_PATH`
resolves to a Windows `makensis.exe`.

## Automated Pull Request Updates

The repository keeps branch protection configured to require pull request
branches to be up to date before merge. To reduce manual queue maintenance,
`.github/workflows/update-automerge-prs.yml` runs after every push to `main`.

The workflow updates open pull request branches when either:

- GitHub auto-merge is enabled for the pull request.
- The pull request has the `automerge` label.

Only pull requests targeting `main` and using branches from this repository are
updated. Fork pull requests, draft pull requests, pull requests targeting other
branches, and pull requests without auto-merge or the label are skipped.

The updater calls GitHub's pull request branch update API, which merges the
latest `main` into the pull request branch. That new branch update re-runs the
required checks, allowing GitHub auto-merge to finish once the branch is current
and checks pass.

If GitHub reports that a branch cannot be updated cleanly, the workflow logs the
conflict and continues with the next pull request instead of blocking the whole
queue. Resolve that pull request manually.

The workflow uses the same GitHub App credentials as the release tag workflow:
repository variable `APP_CLIENT_ID` and repository secret `APP_PRIVATE_KEY`.
Using a GitHub App token keeps branch updates capable of triggering the normal
pull request checks.

To test the candidate set without updating branches, run the workflow manually
with `dry_run` enabled.

## Encoding

`apps/setup/src/nsis/Codex13StudentDevKit.nsi` contains Polish UI strings and is compiled
with `/INPUTCHARSET UTF8`. Avoid whole-file rewrites from tools that may change
encoding.
