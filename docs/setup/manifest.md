# Manifest

Setup writes a manifest after tools, launchers and legal payload files are
prepared:

```text
codex13-sdk.manifest.json
```

The manifest is a required installation artifact. It describes what the current
SDK installation contains and gives the future Manager a stable handoff point.
If Setup cannot create the file, installation is treated as failed.

## Schema Version 1

Example for `classroom` / `php-mysql-classroom`:

```json
{
  "schemaVersion": 1,
  "manifestName": "codex13-sdk.manifest.json",
  "product": "Codex 13 Student Dev Kit",
  "installedAt": "2026-05-04T00:05:52.1575020+02:00",
  "installRoot": "C:\\Users\\User\\AppData\\Local\\Codex13\\StudentDevKit",
  "mode": "install",
  "profile": "classroom",
  "preset": "php-mysql-classroom",
  "components": [
    {
      "id": "vscode",
      "name": "Visual Studio Code",
      "version": "1.118.1",
      "path": "tools\\VSCode",
      "status": "installed",
      "strategy": "refresh-preserve-data"
    },
    {
      "id": "git",
      "name": "Git for Windows",
      "version": "2.54.0",
      "path": "tools\\Git",
      "status": "installed",
      "strategy": "keep-verify"
    },
    {
      "id": "xampp",
      "name": "XAMPP",
      "version": "8.2.12",
      "path": "tools\\xampp",
      "status": "installed",
      "strategy": "keep-or-refresh-preserve-data"
    }
  ],
  "shortcuts": {
    "startMenu": true,
    "desktop": [
      "codex13-launcher",
      "vscode",
      "git-bash",
      "xampp-control"
    ]
  },
  "vscode": {
    "profile": "classroom-php-mysql",
    "portableData": true,
    "launcherAddsSdkToolsToPath": true
  },
  "logPath": "C:\\Users\\User\\AppData\\Local\\Codex13\\StudentDevKit\\logs\\install-20260504-000213.log"
}
```

## Fields

| Field | Description |
| --- | --- |
| `schemaVersion` | Manifest schema version. Current value: `1`. |
| `manifestName` | Manifest file name. Current value: `codex13-sdk.manifest.json`. |
| `product` | Product name. |
| `installedAt` | Local install timestamp in ISO 8601 format. |
| `installRoot` | Absolute SDK installation root. |
| `mode` | Installer mode, for example `install` or `reinstall`. |
| `profile` | Selected profile, for example `start` or `classroom`. |
| `preset` | Selected preset, for example `clean-vscode` or `php-mysql-classroom`. |
| `components` | Installed component records detected from control files. |
| `shortcuts.startMenu` | Whether Start Menu shortcuts are part of the installation contract. |
| `shortcuts.desktop` | Desktop shortcut ids selected during install. |
| `vscode.profile` | VS Code starter settings profile selected by the preset. |
| `vscode.portableData` | Whether VS Code portable data directories are used. |
| `vscode.launcherAddsSdkToolsToPath` | Whether the VS Code launcher adds SDK tools to PATH for that process. |
| `logPath` | Absolute path to the install log for this run. |

Schema version 1 intentionally does not record transient installer inputs such
as `forceDownload`, whether the run used unattended mode, or individual
preservation checkbox values. Those values describe one installer execution, not
the stable installed SDK state that the future Manager should consume.

## Component Detection

The manifest writer records a component only when its control file exists under
the install root:

| Component | Control file |
| --- | --- |
| VS Code | `tools\VSCode\Code.exe` |
| Git for Windows | `tools\Git\git-bash.exe` |
| XAMPP | `tools\xampp\xampp-control.exe` |

OpenSSH is planned for a later release. The manifest writer already knows the
future OpenSSH control file shape, but current profiles do not install it.

`components[].strategy` records the component's current preservation/update
policy as exposed by this alpha installer. It is not a per-run action log. For
example, an existing Git installation may be kept while the manifest still shows
`keep-verify`, and VS Code may show `refresh-preserve-data` as the policy for
the component. When an existing component is kept, Setup checks the installed
control file and skips archive cache verification/download for that component.

## Privacy Note

`installRoot` and `logPath` are absolute local paths. They can include the
Windows user profile name or another user-selected directory name. The manifest
is written locally to the install root and is not transmitted by Setup.
