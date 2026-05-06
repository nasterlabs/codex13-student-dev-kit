# Installer payload

Put files and directories here when they should be copied directly to the
installation directory (`$INSTDIR`).

Examples:

- `legal/` -> `$INSTDIR\legal\`
- `licenses/` -> `$INSTDIR\licenses\`
- `NOTICE.txt` -> `$INSTDIR\NOTICE.txt`

The installer copies this directory after preparing `$INSTDIR` and before
installing bundled tools.

Tool binaries are installed by the NSIS script under `$INSTDIR\tools`.
Downloaded archives are cached under `$INSTDIR\packages`.
Wrapper scripts live under `$INSTDIR\bin`.
Installation logs are appended under `$INSTDIR\logs`.
