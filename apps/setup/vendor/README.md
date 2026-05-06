# Setup Vendor Binaries

The Setup installer vendors a small number of binary tools because NSIS needs
them at compile time or installer runtime. They are kept in the repository so
builds can verify fixed local inputs without downloading executable code during
the build.

| Binary | Origin | License | Update method |
| --- | --- | --- | --- |
| `plugins/x86-unicode/INetC.dll` | Vendored from the NSIS INetC plug-in distribution | zlib/libpng (NSIS project license) | Download the required Unicode plug-in binary from the documented upstream source, replace this file only, update third-party metadata, regenerate `vendor.sha256`, and verify locally. |
| `plugins/x86-unicode/nasterarchive.dll` | Internal build artifact generated from `packages/nsis-naster-archive/` in this repository | MIT for package code, with NSIS plug-in API helpers under zlib/libpng | Build the package from this repository, copy the resulting DLL into this location, regenerate `vendor.sha256`, and verify locally. |
| `tools/7zip/7za.exe` | 7-Zip Extra package | LGPL-2.1-or-later for most code, with BSD-3-Clause and BSD-2-Clause code in `7za.exe` | Download the documented 7-Zip Extra version, replace this executable only, preserve applicable 7-Zip license notices, update third-party metadata, regenerate `vendor.sha256`, and verify locally. |

`nasterarchive.dll` is not third-party. It is vendored only because NSIS expects
a DLL plug-in to be present while compiling the installer.

## Integrity Verification

Expected SHA256 checksums are stored in `apps/setup/vendor/vendor.sha256`.
Verify the vendored binaries from the repository root:

```powershell
./scripts/verify-vendor.ps1
```

The script performs deterministic local verification only. It does not download
or refresh any binary.

## Updating Vendored Binaries

1. Download or build the new binary from the documented source.
2. Replace only the required binary.
3. Update `docs/third-party.md` with version, source, license, and update date.
4. Regenerate `apps/setup/vendor/vendor.sha256`.
5. Run `./scripts/verify-vendor.ps1`.
6. Commit the binary, checksum, and documentation changes together.
