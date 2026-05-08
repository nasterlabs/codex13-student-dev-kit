# Codex 13 SDK - XAMPP Unicode path patch
<!-- cspell:ignore ukasz -->

This directory contains Codex 13 Student Development Kit modifications for the XAMPP Windows installer/configuration files.

The original XAMPP files come from the Apache Friends XAMPP for Windows package:

- project: Apache Friends XAMPP
- upstream site: https://www.apachefriends.org/
- relevant original file: `xampp/install/install.php`
- original script notice: `Installer PHP 1.5`, Kay Vogelgesang & Carsten Wiedmann for www.apachefriends.org, 2005
- upstream package license: GPL-2.0-only for the XAMPP compilation, as declared
  by the Apache Friends project listing on SourceForge

Modifications were prepared by **Naster Labs**, the software brand of
**Luczak Consulting P.S.A.**, for **Codex 13 Student Dev Kit**.

- repository: https://github.com/nasterlabs/codex13-student-dev-kit
- product page: https://codex13.dev/student-dev-kit

## Problem

The original XAMPP relocation flow uses `install/config.awk` and executes it through the Windows command-line layer. On machines where the installation path contains non-ASCII characters, for example:

```text
C:\Users\Łukasz\AppData\Local\Codex13\StudentDevKit\xampp
```

configuration files can be rewritten incorrectly, for example:

```apache
ServerRoot "/Users/ ukasz/AppData/Local/Codex13/StudentDevKit/xampp/apache"
```

or duplicated path fragments can appear after repeated repair attempts.

The result is Apache failing with errors such as:

```text
ServerRoot must be a valid directory
```

## Files

| File | Purpose |
| --- | --- |
| `install.php` | Replacement for `xampp/install/install.php`. Keeps path relocation inside PHP instead of using `awk.exe`. |
| `install.original.php` | Copy of the upstream XAMPP installer script kept beside the replacement for traceability. |
| `repair-xampp-paths.php` | Repair utility for already damaged XAMPP configuration files. |
| `verify-xampp-paths.php` | Post-install validation utility used by the Setup patch pipeline. |
| `diagnose-php-extensions.php` | Manual diagnostic for PHP, `php.ini` and extension loading. It does not start services. |
| `verify-xampp-runtime.php` | Manual runtime diagnostic for Apache, MySQL, PHP and phpMyAdmin after services are started. |

## License and source

The upstream `install.php` file does not carry a dedicated SPDX identifier or
per-file license header. It is distributed as part of the XAMPP for Windows
package. The Apache Friends project listing on SourceForge declares XAMPP as
GPLv2, and Apache Friends describes the XAMPP compilation as distributed under
the GNU General Public Licence while individual bundled components keep their
own licenses.

Codex 13 therefore treats `install.original.php` and the modified
`install.php` replacement as `GPL-2.0-only`. The accompanying `repair` and
`verify` helpers are distributed under the same GPL-2.0-only terms to keep the
patch set simple and compatible.

The complete corresponding source for the XAMPP patch set is this directory.
No separate written source offer is needed for the repository distribution
because the source is published directly. Installer builds also install the PHP
patch files as source text under `tools\xampp\install\`.

## Usage in SDK build

Setup overlays the files from:

```text
apps/setup/src/patches/xampp/root/
```

onto the installed XAMPP root. The final runtime files are:

```text
xampp\install\install.php
xampp\install\install.original.php
xampp\install\repair-xampp-paths.php
xampp\install\verify-xampp-paths.php
xampp\install\diagnose-php-extensions.php
xampp\install\verify-xampp-runtime.php
```

The patch manifest files in `apps/setup/src/patches/xampp/` drive the runtime
pipeline:

| File | Purpose |
| --- | --- |
| `delete.txt` | Removes legacy patch export files such as `install.codex13-unicode.php` before overlaying the final files. |
| `commands.txt` | Runs the repair helper from the XAMPP root after the overlay. |
| `validations.txt` | Runs `verify-xampp-paths.php` and `httpd.exe -t` after `setup_xampp.bat`. |

`diagnose-php-extensions.php` and `verify-xampp-runtime.php` are installed for
manual diagnostics only. They are intentionally not listed in `commands.txt` or
`validations.txt`: the extension diagnostic is useful when investigating
`php.ini` and DLL loading without services, while the runtime diagnostic needs
Apache and MySQL to be running and therefore must not block unattended Setup.

For a damaged local installation, run from the XAMPP root:

```powershell
.\php\php.exe -n .\install\repair-xampp-paths.php
.\php\php.exe -n .\install\verify-xampp-paths.php
.\apache\bin\httpd.exe -t
```

`verify-xampp-paths.php` performs static file validation without services.
`diagnose-php-extensions.php` checks PHP, `php.ini`, `extension_dir` and PHP
extension DLL loading without services. `verify-xampp-runtime.php` checks the
Apache/MySQL/phpMyAdmin runtime and requires Apache and MySQL services to be
started first.

Expected result:

```text
Syntax OK
```

## Change markers

Code changed for Codex 13 SDK is marked with comments such as:

```php
// [CODEX13-SDK PATCH START]
// [CODEX13-SDK PATCH END]
// [CODEX13-SDK PHP INI PATCH START]
// [CODEX13-SDK PHP INI PATCH END]
// [CODEX13-SDK REPAIR]
```
