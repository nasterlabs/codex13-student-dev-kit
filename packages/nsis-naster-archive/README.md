# NSIS Naster Archive

NSIS Naster Archive is a Unicode NSIS plug-in for archive operations with an
installer-friendly progress UI.

The project is authored and maintained by **Naster Labs**.

For more information, see https://naster.dev

Contact: <support@naster.dev>

## Status

Current implemented command:

- `nasterarchive::extract` - extract a ZIP or 7z archive through `7za.exe`.

Planned commands:

- extract a single file or a selected path from an archive;
- create a new archive, for example to back up `htdocs`;
- add one or more files to an existing archive.

The current command keeps the same argument contract that Codex 13 Setup uses
for archive extraction.

## NSIS Usage

```nsis
!addplugindir "plugins\x86-unicode"

nasterarchive::extract \
  /NSISDL \
  /7ZIP "$SevenZipPath" \
  /CAPTION "Extracting Visual Studio Code" \
  /TEXT "Extracting Visual Studio Code... please wait." \
  /CANCELTEXT "Cancel" \
  /QUESTION "Cancel extraction?" \
  "$CacheDir\vscode.zip" \
  "$INSTDIR\tools\vscode" \
  /END
Pop $0
```

The command returns one stack value:

- `OK` - extraction completed;
- `cancel` - the user cancelled extraction;
- any other string - an error message.

## Options

- `/NSISDL` - show embedded progress and cancel UI on the NSIS install files page.
- `/7ZIP <path>` - path to `7za.exe`; required.
- `/EXCLUDE <pattern>` - repeatable 7-Zip exclude pattern.
- `/CAPTION <text>` - text shown above the installer page progress bar.
- `/TEXT <text>` - text shown above the embedded archive progress bar.
- `/CANCELTEXT <text>` - embedded cancel button text.
- `/QUESTION <text>` - confirmation prompt before cancelling.

Positional arguments:

1. Archive path.
2. Destination directory.
3. `/END`.

Without `/NSISDL`, extraction still runs synchronously and returns a stack
result, but the plug-in does not create embedded progress UI.

## Build

Build from the repository root on Windows:

```powershell
task build:nsis-naster-archive
```

Or build from this package directory:

```powershell
task build
```

The canonical build artifact is written to:

```text
dist/nsis-naster-archive/plugins/x86-unicode/nasterarchive.dll
```

By default the build also copies the DLL into:

```text
apps/setup/vendor/plugins/x86-unicode/nasterarchive.dll
```

Use `task build:no-copy` inside this package to skip copying into Setup.

## Repository Layout

- `src/` - native C++ NSIS plug-in source and MSBuild project.
- `src/nsis-plugin-api/` - minimal NSIS plug-in API helpers used by the build.
- `docs/` - usage notes, compatibility and roadmap.
- `examples/` - small NSIS scripts showing plug-in calls.
- `THIRD-PARTY-NOTICES.md` - upstream notices for bundled helper files.

## Compatibility

The current build targets the NSIS Unicode plug-in ABI folder
`x86-unicode`. That folder name describes the NSIS plug-in ABI, not simply the
target Windows architecture.

## Contributing

Contributions are welcome.

By submitting a contribution to this repository, you agree that your work
will be licensed under the MIT License.

Please ensure that:

- your code builds correctly;
- changes are focused and minimal;
- any relevant documentation is updated.

By contributing, you confirm that you have the right to license your contribution
under the terms of the MIT License.

For larger changes, consider opening an issue first to discuss the approach.

## Author

Naster Labs is a software engineering brand of Luczak Consulting P.S.A.

## License

This project is licensed under the MIT License.

Copyright (c) 2026 Naster Labs (a brand of Luczak Consulting P.S.A.)

See the `LICENSE` file for the full license text.

Third-party components may be distributed under their own licenses.
See `THIRD-PARTY-NOTICES.md` for details.
