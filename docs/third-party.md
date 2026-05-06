# Third-Party Components

This repository vendors selected binaries and source fragments so the installer
can build reproducibly.

The main project code is licensed as Apache License 2.0 (`Apache-2.0`), with
per-path exceptions recorded in `.reuse/dep5`. In particular, the
upstream-derived XAMPP patch set is kept as `GPL-2.0-only` and separate from the
Apache-2.0 installer code. Vendored and downloaded third-party components remain
governed by their own license terms.

## Vendored In Repository

| Component | Location | Purpose | Version | Origin | License | Classification | Source | Metadata updated |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 7-Zip Extra | `apps/setup/vendor/tools/7zip/7za.exe`, `apps/setup/vendor/tools/7zip/License.txt` | ZIP/7z extraction backend | 26.01 | 7-Zip Extra package | LGPL-2.1-or-later for most code, with BSD-3-Clause and BSD-2-Clause code in `7za.exe` | Third-party binary | <https://www.7-zip.org/download.html> | 2026-05-06 |
| INetC NSIS plugin | `apps/setup/vendor/plugins/x86-unicode/INetC.dll` | HTTP/FTP download | 1.0 (2015) | NSIS INetC plug-in distribution | zlib/libpng (NSIS project license) | Third-party binary | <https://nsis.sourceforge.io/Inetc_plug-in> | 2026-05-06 |
| LoadRTF NSIS header | `apps/setup/src/nsis/include/LoadRTF.nsh` | Streams generated RTF into installer RichEdit controls | 2010 wiki header | NSIS wiki header | zlib/libpng (NSIS project license) | Third-party source/header | <https://nsis.sourceforge.io/LoadRTF> | 2026-05-06 |
| NSIS Naster Archive plugin | `apps/setup/vendor/plugins/x86-unicode/nasterarchive.dll`, `packages/nsis-naster-archive/` | Cancellable archive operations | 0.1.0 | Built from this repository | MIT (package code) + NSIS plug-in API helpers (zlib/libpng) | Internal build artifact | This repository | 2026-05-06 |
| XAMPP patch scripts | `apps/setup/src/patches/xampp/` | Portable XAMPP path-relocation fix | — | Upstream-derived patch set | GPL-2.0-only | Third-party-derived source patches | See `LICENSES/LicenseRef-xampp-patch.txt` | 2026-05-06 |

License texts for vendored binaries are in
`apps/setup/vendor/tools/7zip/License.txt` and the respective upstream projects.
The 7-Zip license is reproduced in `apps/setup/vendor/tools/7zip/License.txt`
as required by its redistribution terms; redistribution requires preserving the
applicable 7-Zip license notices.

`apps/setup/vendor/plugins/x86-unicode/nasterarchive.dll` is not third-party. It
is an internal build artifact generated from `packages/nsis-naster-archive/` and
vendored because NSIS needs the plug-in DLL at compile time.

`apps/setup/vendor/plugins/x86-unicode/INetC.dll` is vendored from the NSIS
INetC plug-in distribution. Preserve its source URL, version, update date, and
SHA256 metadata when updating it because the upstream packaging is not as modern
as current package registries.

## Vendored binary integrity

Vendored binaries are tracked in `apps/setup/vendor/vendor.sha256`.
Every CI run should verify these files with `scripts/verify-vendor.ps1`.

Changing a vendored binary without updating the corresponding third-party
metadata and SHA256 checksum is considered a release-blocking issue.

Update procedures for vendored binaries are documented in
`apps/setup/vendor/README.md`.

## Downloaded By Current Profiles

| Component | Version | Config | License |
| --- | --- | --- | --- |
| Visual Studio Code portable | pinned in `apps/setup/src/nsis/config.nsh` | `VSCODE_*` defines | Microsoft Software License Terms for the Microsoft binary; Code - OSS source is MIT; third-party notices in `apps/setup/src/payload/licenses/vscode/NOTICE.txt` |
| Git for Windows portable | pinned in `apps/setup/src/nsis/config.nsh` | `GIT_*` defines | Git is GPL v2 with compatible per-file licenses; the Git for Windows bundle also includes Bash, zlib, curl, Tcl/Tk, Perl, MSYS2, GNU utilities and other components under their own terms |
| XAMPP portable | pinned in `apps/setup/src/nsis/config.nsh` | `XAMPP_*` defines | Multi-component bundle; includes Apache-2.0, GPL-2.0, PHP-3.01, Artistic/GPL and other component licenses; full upstream license tree is installed under `tools\xampp\licenses` |

## Planned Downloaded Components

| Component | Version | Config | License |
| --- | --- | --- | --- |
| OpenSSH for Windows | pinned in `apps/setup/src/nsis/config.nsh` | `OPENSSH_*` defines | ISC/BSD-family and public-domain notices; upstream states OpenSSH contains no GPL code |
| Node.js portable | planned | not wired yet | not finalized |
| ImageMagick portable | planned | not wired yet | not finalized |

Each downloaded component is governed by its own license terms. The installer
does not bundle these archives; it downloads them at install time from their
official upstream sources as configured in `apps/setup/src/nsis/config.nsh`.

License payloads copied by Setup are maintained under
`apps/setup/src/payload/licenses/`. For large bundles, those payload files are a
front door to the upstream license trees included in the downloaded package,
not a replacement for every component notice inside that package.
