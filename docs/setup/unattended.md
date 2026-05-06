# Unattended Installation

Unattended mode is implemented as an answer file placed next to the installer:

```text
codex13-sdk.unattended.ini
```

The current implementation is intentionally all-or-nothing. If the answer file is
complete and every value is supported, Setup accepts the whole configuration and
runs automatically. If anything required is missing, invalid or unsupported,
Setup ignores the file and starts the normal manual wizard without applying any
partial choices from that file.

## Example

```ini
[legal]
acceptLicense=true
acceptThirdParty=true
acceptPrivacy=true

[install]
installDir={localappdata}\Codex13\StudentDevKit
profile=classroom
preset=php-mysql-classroom
forceDownload=false
showDetails=false
```

## Required Sections

The `[legal]` section must contain all required confirmations:

| Key | Required value |
| --- | --- |
| `acceptLicense` | `true` |
| `acceptThirdParty` | `true` |
| `acceptPrivacy` | `true` |

The `[install]` section must contain a complete supported installation choice:

| Key | Description |
| --- | --- |
| `installDir` | Target installation directory. |
| `profile` | Supported values: `start`, `classroom`. |
| `preset` | Supported values depend on `profile`. |
| `forceDownload` | Optional. `true` forces package redownload; any other value is treated as false. |
| `showDetails` | Optional. `true` shows detailed installation log output; any other value is treated as false. |

## Supported Profiles And Presets

The answer file supports the same choices that can currently be selected by hand:

| Profile | Preset | Installed tools |
| --- | --- | --- |
| `start` | `clean-vscode` | Portable Visual Studio Code. |
| `classroom` | `php-mysql-classroom` | Portable Visual Studio Code, portable Git for Windows, portable XAMPP. |

Other profiles, presets and component-level selections are planned for later
releases. They are rejected by the current unattended parser.

## Install Directory Expansion

`installDir` supports normal Windows environment variable expansion, for example
`%USERPROFILE%`, and these placeholders:

| Placeholder | Expands to |
| --- | --- |
| `{localappdata}` | Current user's Local AppData directory. |
| `{appdata}` | Current user's Roaming AppData directory. |
| `{userprofile}` | Current user's profile directory. |
| `{desktop}` | Current user's Desktop directory. |
| `{documents}` | Current user's Documents directory. |
| `{programfiles}` | Program Files directory. |
| `{temp}` | Temporary directory. |

## Running

For visible unattended mode, place `codex13-sdk.unattended.ini` in the same
directory as the installer and run the installer normally:

```powershell
.\Codex13SDK-Setup.exe
```

For silent unattended mode, use:

```powershell
.\Codex13SDK-Setup.exe /unattended-silent
```

`/unattended-silent` is honored only after a valid answer file is accepted. If
the answer file is missing or invalid, Setup falls back to the normal manual
wizard.

## Portable Environment Behavior

All selected tools are installed inside `installDir`. Setup does not configure a
global system PATH. Codex 13 launcher scripts set environment variables only for
the process they start, so multiple independent installations can live side by
side as long as each one uses its own directory.

## Planned Expansion

Future releases may add command-line flags, partial answer files, explicit
component selections, shortcut selections, existing-component policies and a
validate-only preflight mode. The current release deliberately accepts only the
complete answer-file shape documented above.
