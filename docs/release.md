# Release Process

This repository uses GitHub Flow and Conventional Commits.

## Version Source

The installer product version core is defined in `apps/setup/src/nsis/config.nsh`:

```nsis
!define APP_VERSION "0.7.0"
```

`package.json` stores the repository package version used by tooling and release
preparation. The actual installer build version is resolved by
`apps/setup/scripts/build.ps1` from `BUILD_VERSION`.

`APP_VERSION` is the source of truth for the installer version core
(`major.minor.patch`). Release tags and manual release workflow test versions
may add prerelease or build metadata, but their SemVer core must match
`APP_VERSION`. For example, while `APP_VERSION` is `0.7.0`, these versions are
valid release workflow inputs:

```text
v0.7.0-alpha.1
v0.7.0-alpha.1+test.0
```

This version is rejected until `APP_VERSION` is updated to `0.7.1` in
`apps/setup/src/nsis/config.nsh`:

```text
v0.7.1-alpha.1
```

Before starting a release PR, create a release branch and prepare the mechanical
version/changelog changes:

```powershell
task release:prepare TAG=v0.7.0-alpha.1
```

This creates `release/v0.7.0-alpha.1` from `origin/main`, updates versioned
source files, including `APP_VERSION` in `apps/setup/src/nsis/config.nsh` when
the SemVer core changes, updates `package.json`, refreshes citation/archive
metadata, and inserts a generated changelog section after the
`<!-- New release entries go here -->` marker.

After that:

1. Manually edit the generated `CHANGELOG.md` section.
2. Remove the temporary release-description and highlight edit markers.
3. Review version changes and any related documentation.
4. Conclude the release branch:

   ```powershell
   task release:conclude TAG=v0.7.0-alpha.1
   ```

   Add `OPEN_PR=1` to push the branch and open the PR with GitHub CLI:

   ```powershell
   task release:conclude TAG=v0.7.0-alpha.1 OPEN_PR=1
   ```

`release:conclude` validates `package.json`, `APP_VERSION`, release metadata,
and the changelog markers, runs repository checks, then commits the branch as
`chore(release): prepare v<semver>`.

The release workflow validates this before the expensive release build job. If
the version core does not match `APP_VERSION`, the run fails in
`Pre-release checks` and links back to this section.

## Failed Alpha Release Recovery

Alpha suffixes are intentionally monotonic. If a release PR was merged but the
tag or release workflow failed before publishing a GitHub Release, do not reuse
the same tag. Prepare the next alpha number instead.

For example, if `v0.7.0-alpha.1` was merged to `main` but no tag and no GitHub
Release were published, recover with:

```powershell
task release:retry TAG=v0.7.0-alpha.2 SUPERSEDE_TAG=v0.7.0-alpha.1
```

This creates `release/v0.7.0-alpha.2` from `origin/main`, updates versioned
files, and moves the existing changelog section from the failed tag to the
new tag. It does not add a second copy of the changelog entry, so the next
published release reads as if the failed alpha was never released.

The helper also asks git-cliff for the changes that landed after the failed
tag. When git-cliff finds follow-up changes, it inserts them into the moved
changelog entry inside `BEGIN RELEASE RETRY FOLLOW-UP` markers so the manual
editing step starts from generated text instead of a raw commit list. If
git-cliff does not find a usable follow-up section, the helper falls back to
printing the follow-up commits for manual review.

After the retry branch is created:

1. Review the updated changelog section.
2. Merge or rewrite any `BEGIN RELEASE RETRY FOLLOW-UP` block into the final
   changelog prose.
3. Remove any temporary edit markers that remain.
4. Conclude and open the release PR:

   ```powershell
   task release:conclude TAG=v0.7.0-alpha.2 OPEN_PR=1
   ```

If a tag exists but the GitHub Release failed, inspect the failed run before
choosing the recovery path. A published tag is immutable release history; prefer
fixing the release workflow and publishing from the existing tag only when the
artifacts were not published and the tag points to the intended commit.

The first public release line uses a numeric alpha build suffix:

```text
0.7.0-alpha.<build_number>
```

Release tags must use:

```text
v0.7.0-alpha.<build_number>
```

These first alpha releases are intended to be stable enough for release
validation, but they also validate the GitHub release workflow, artifacts,
checksums and public release notes. Until Authenticode signing for the EXE is
resolved, public releases remain alpha releases.

## Release PR and Tagging

Release preparation happens in a `release/v<semver>` branch and a normal GitHub
Flow pull request. The release PR is the place to review generated changelog
text, version bumps and release metadata before anything is tagged.

The release commit subject must be:

```text
chore(release): prepare vX.Y.Z
```

For example:

```text
chore(release): prepare v0.7.0-alpha.1
```

After the release PR is merged to `main`, `.github/workflows/tag-release.yml`
runs on the closed pull request event. It only continues for merged PRs whose
source branch starts with `release/`, validates the release state, and creates an
annotated `vX.Y.Z` tag on the merge commit. The tag push then starts
`.github/workflows/release.yml`, which builds and publishes the GitHub Release.

The tag workflow validates that:

- the release PR source branch matches `release/v<semver>`,
- `package.json` has the same full SemVer version,
- `APP_VERSION` matches the release version core,
- `CHANGELOG.md` contains a section for that version,
- the tag does not already exist.

It does not validate the merge commit subject. GitHub can rewrite that subject
depending on whether the PR was merged with a merge commit, squash merge or
rebase merge, while the release branch name and versioned files are the actual
release state.

To validate the tag workflow without creating a tag, run the `Tag release`
workflow manually with `dry_run` enabled. Use the release branch name and the
commit or branch to validate. The default manual mode validates and stops before
the tag creation step.

Local validation uses the same release-state checker:

```powershell
task release:check-state RELEASE_BRANCH=release/v0.7.0-alpha.1
```

The tag workflow creates a GitHub App installation token with
`actions/create-github-app-token`. Configure repository variable
`APP_CLIENT_ID` and repository secret `APP_PRIVATE_KEY` for an app installation
that can write repository contents. The shared repository GitHub App setup,
including required permissions, is documented in
[`docs/development.md`](development.md#repository-github-app). Do not use the
workflow `GITHUB_TOKEN` for this job: GitHub does not start new `push` workflow
runs from tags pushed by `GITHUB_TOKEN`, so the release workflow would not start
automatically.

## Changelog Preparation

`CHANGELOG.md` is generated before the release PR and then reviewed like any
other source file. The generator prepares the first draft; humans may edit the
wording, remove noise, add context or regroup entries before merge.

Preview the generated changelog section:

```powershell
pnpm changelog --tag v0.7.0-alpha.1
```

Prepare a release changelog section by inserting it into `CHANGELOG.md`:

```powershell
pnpm changelog:write --tag v0.7.0-alpha.1
```

The `--tag` value controls the generated section heading. For example,
`--tag v0.7.0-alpha.1` produces `## [0.7.0-alpha.1] - <date>` instead of
`## [Unreleased]`. The changelog write command inserts the generated section
immediately after the `<!-- New release entries go here -->` marker, leaving the
existing changelog body below it intact. If the same version already exists in
`CHANGELOG.md`, update that section manually instead of running the insertion
command again.

The changelog generator is `git-cliff`, configured in `.git-cliff.toml` for
Conventional Commits. The committed `CHANGELOG.md` remains the source that is
reviewed in the release PR.

The full release branch helper wraps this changelog command:

```powershell
task release:prepare TAG=v0.7.0-alpha.1
```

## Local Release Build

Copy `.env.prod.example` to `.env.prod`, set `BUILD_VERSION` for a public
candidate when needed, and then run:

```powershell
task build:prod
```

`task build:release` is a backward-compatible alias for the same task.

The release installer is written to:

```text
dist\setup\Codex13SDK-Setup.exe
```

For local release builds, set `BUILD_VERSION=0.7.0-alpha.<build_number>` in
`.env.prod` when preparing a public candidate. If omitted, the build script uses
`0.7.0-alpha.local`, which is only for local validation.

## GitHub Release

The release workflow:

1. runs repository checks,
2. rebuilds `nasterarchive.dll` on Windows,
3. builds the installer on Windows,
4. leaves signing disabled by default for the current alpha line,
5. generates GitHub changelog notes from merged pull requests,
6. generates `codex13-sdk_<version>_release_manifest.json`,
7. generates one `codex13-sdk_<version>_checksums.txt` file for release assets,
8. uploads installer, checksums, release manifest and release notes to the
   workflow artifact,
9. publishes installer, checksums and release manifest to a GitHub Release when
   the run is allowed to publish one.

On tag builds, the workflow derives `BUILD_VERSION` from the tag name. Manual
workflow dispatch can use an explicit test version such as
`v0.7.0-alpha.1+test.0`; if the field is empty, the workflow uses
`v<APP_VERSION>-alpha.<github_run_number>`.

## Release Manifest

Every release publishes `codex13-sdk_<version>_release_manifest.json` next to
the installer and one SHA256 checksum file covering all uploaded release
assets. The release manifest is generated from `apps/setup/src/nsis/config.nsh`,
so pinned tool versions, download URLs and SHA256 values stay aligned with the
installer source.

The manifest records:

- product and build version,
- Setup installer profiles and their selected tool sets,
- installable/supported tools for the current release,
- uploaded release asset metadata,
- pinned metadata for planned-but-hidden tools such as OpenSSH.

The release workflow also generates
`codex13-sdk_<version>_release_notes.md` from the release manifest and the
reviewed `CHANGELOG.md` entry for the release. The visible release description
and highlights come from `CHANGELOG.md`; profile, tool and asset tables come
from the manifest. The notes file is uploaded as a workflow artifact for
troubleshooting and used as the GitHub Release body.

GitHub-generated notes are still produced during the workflow as a fallback and
diagnostic input, but the repository `CHANGELOG.md` remains the manually
reviewable changelog prepared in the release PR.

## Citation and Archive Metadata

For public releases, update the repository-level research/archive metadata so it
matches the published artifact:

- `CITATION.cff`: update `version`, `date-released`, `commit` and the release
  `identifiers` entry. When a Zenodo DOI exists, add or replace the identifier
  with the DOI assigned to that release.
- `.zenodo.json`: keep title, description, creators, ORCID, license and
  keywords aligned with the public release metadata. Zenodo prefers
  `.zenodo.json` over `CITATION.cff` when both files exist.
- `codemeta.json`: update `version`, `datePublished`, `releaseNotes` and any
  repository/release URLs that changed for the release.

Use the metadata helper before creating a public release tag:

```powershell
task release:metadata -- -BuildVersion 0.7.0-alpha.<build_number>
```

`task release:prepare` runs the same helper for the release branch so the
repository metadata moves with the version bump. The release workflow also runs
the helper again in its build workspace with the exact tag build SHA, so the
uploaded/generated release metadata is consistent with `BUILD_VERSION` and the
release tag.

After Zenodo assigns a DOI, run the helper again with `-Doi <doi>` before the
next metadata commit or release metadata refresh.

## Authenticode Signing

The first `0.7.0-alpha.<build_number>` releases ship unsigned. Signing will be
added in a follow-up release once a certificate is in place. Until that is done,
every public release remains an alpha release.

The CI release workflow is intentionally configured to pass without signing:
`SIGNING_ENABLED=0` is written to `.env` during the workflow. The release body
also states that the installer executable is currently unsigned.

### Development signing

Development builds may be unsigned or signed with a local self-signed
certificate. This is only for local testing and does not make a public release
trusted by Windows SmartScreen.

Generate and trust a local development certificate:

```powershell
task signing:dev-cert
```

Then add the generated values to `.env.dev` or `.env`:

```text
SIGNING_ENABLED=1
SIGN_CERT_THUMBPRINT=<thumbprint z setup-dev-cert.ps1>
SIGN_TIMESTAMP_URL=http://timestamp.digicert.com
```

To build without signing, keep `SIGNING_ENABLED=0` or omit signing variables.

### Production signing plan

Production signing is not enabled for the first public alpha releases. Once a
certificate is available, enable the existing optional release workflow step by
setting repository variable `RELEASE_SIGNING_ENABLED=1` and adding these GitHub
Actions secrets:

| Secret name           | Description                                      |
|-----------------------|--------------------------------------------------|
| `SIGN_PFX_BASE64`     | Base64-encoded PFX file with the private key     |
| `SIGN_PFX_PASSWORD`   | Password for the PFX file                        |
| `SIGN_TIMESTAMP_URL`  | RFC 3161 timestamp server URL; optional override |

When `RELEASE_SIGNING_ENABLED` is not `1`, these secrets are not required and
release builds remain unsigned.

When a production Authenticode certificate is ready, configure signing in this
order:

1. Export the code-signing certificate, including the private key, as a password
   protected `.pfx` file on a trusted machine.
2. Encode the PFX as base64:

   ```powershell
   [Convert]::ToBase64String([IO.File]::ReadAllBytes("C:\certs\codex13-release.pfx"))
   ```

3. Add `SIGN_PFX_BASE64` and `SIGN_PFX_PASSWORD` as GitHub Actions repository
   secrets.
4. Optionally add `SIGN_TIMESTAMP_URL` as a GitHub Actions repository secret.
   If omitted, the build uses `http://timestamp.digicert.com`.
5. Set repository variable `RELEASE_SIGNING_ENABLED` to `1`.
6. Run the release workflow and verify that the `Configure production signing`
   step imports the certificate and the build signs the installer.

The default timestamp URL intentionally uses DigiCert's documented HTTP RFC
3161 endpoint for Microsoft SignTool. Do not change it to HTTPS without testing
SignTool first; HTTPS endpoints are not interchangeable for this service.

Do not commit the PFX file, the base64 value, or the password. The release
workflow imports the certificate into the Windows certificate store during the
job and signs by thumbprint, so the PFX password is not written to `.env` or
`GITHUB_ENV`. The build script itself only reads `SIGN_CERT_THUMBPRINT`; it does
not read PFX paths or PFX passwords.

The build script also supports direct environment variables for local or custom
CI signing when the certificate is already available in `CurrentUser\My`:

```text
SIGNING_ENABLED=1
SIGN_CERT_THUMBPRINT=<CurrentUser\My thumbprint>
SIGN_TIMESTAMP_URL=http://timestamp.digicert.com
```

Development and release builds use the same signing variables; set
`SIGNING_ENABLED=1` for any build that should be signed.

### Certificate paths

- **SignPath Foundation** — we are evaluating/applying for open-source code
  signing through SignPath Foundation. SignPath describes this as free code
  signing for qualifying open-source projects and links the signed binary to the
  public repository: <https://signpath.org/>.
- **Commercial CA** — if the project is not eligible for the foundation route,
  use a commercial Authenticode certificate provider. Project sponsorship may be
  used for release infrastructure such as code-signing certificates.

## Manual Smoke Test

Manual installer execution is intentional, not routine. It downloads external
archives and modifies the selected install directory.

Recommended smoke-test checklist:

- use a disposable install root,
- install the Start / Clean VS Code profile,
- install the Classroom / PHP + MySQL profile,
- verify launchers and shortcuts,
- verify `codex13-sdk.manifest.json`,
- verify the manifest contains selected profile, preset, installed components,
  shortcut ids, VS Code portable data state and install log path,
- uninstall while preserving user data,
- check installer logs.
