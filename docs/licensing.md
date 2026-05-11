# Licensing And Notices

Codex 13 Student Dev Kit is maintained as an open-source monorepo, but not
every file in the repository has the same license or copyright origin.

## Default Project License

The default project license is Apache License 2.0 (`Apache-2.0`). The root
`LICENSE` file intentionally contains the full official Apache License 2.0 text,
including the appendix that explains how to apply the license to a work. That
appendix is part of the canonical license text and should not be edited out.

`NOTICE` records the project-level attribution for Codex 13 Student Dev Kit.

## Per-Path License Map

`.reuse/dep5` is the source of truth for repository paths that need a more
specific license statement than the default root license. Important exceptions
include:

- `packages/nsis-naster-archive/**` - MIT-licensed internal NSIS plug-in code.
- `packages/nsis-naster-archive/src/nsis-plugin-api/**` - NSIS plug-in API
  helper headers under the zlib/libpng license.
- `apps/setup/src/patches/xampp/**` - GPL-2.0-only upstream-derived XAMPP patch
  set.
- `apps/setup/vendor/**` and installer payload license texts - third-party
  files governed by their own upstream terms.

When adding a new package, vendored binary, upstream-derived patch, or generated
license payload, update `.reuse/dep5`, `docs/third-party.md`, and the relevant
payload notice files together.

## Downloaded Tools

Setup downloads selected tools during installation. These archives are not
relicensed by this project. Visual Studio Code, Git for Windows, XAMPP,
OpenSSH, and future downloaded tools remain governed by their own upstream
license terms, notices, and source-offer obligations.

The installer copies project and third-party notices into the installed SDK so
users can inspect the applicable terms locally:

- `legal/LICENSE.txt`
- `legal/NOTICE.txt`
- `legal/THIRD-PARTY-NOTICES.txt`
- `licenses/<component>/...`

`docs/third-party.md` summarizes the components, versions, sources, and license
classifications currently known to the project.

## SPDX Headers

Use SPDX file headers for source files where the file format has a natural
comment syntax and the file is not a verbatim upstream notice or generated
artifact. Do not add project SPDX headers to third-party license texts, upstream
notice files, binary metadata dumps, or files that are intentionally copied
verbatim from another project.

For repository-wide exceptions and files without practical inline headers,
prefer `.reuse/dep5` over noisy or misleading per-file comments.
