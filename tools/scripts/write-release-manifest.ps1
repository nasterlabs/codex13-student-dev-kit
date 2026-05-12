param(
    [Parameter(Mandatory = $true)]
    [string] $BuildVersion,

    [string] $ConfigPath = "apps/setup/src/nsis/config.nsh",

    [string] $OutputPath = "",

    [string] $ReleaseNotesPath = "",

    [string] $ChangelogOutputPath = "",

    [string] $GeneratedNotesPath = ""
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$Root = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot "..\..")).Path

function Resolve-RepoPath {
    param(
        [Parameter(Mandatory = $true)]
        [string] $Path
    )

    if ([System.IO.Path]::IsPathRooted($Path)) {
        return $Path
    }

    return Join-Path $Root $Path
}

function Get-NsisDefines {
    param(
        [Parameter(Mandatory = $true)]
        [string] $Path
    )

    $defines = @{}
    foreach ($line in Get-Content -LiteralPath $Path) {
        $match = [regex]::Match($line, '^\s*!define\s+([A-Za-z0-9_]+)\s+"([^"]*)"')
        if ($match.Success) {
            $defines[$match.Groups[1].Value] = $match.Groups[2].Value
        }
    }

    return $defines
}

function Expand-NsisValue {
    param(
        [Parameter(Mandatory = $true)]
        [string] $Value,

        [Parameter(Mandatory = $true)]
        [hashtable] $Defines
    )

    $null = $Defines

    return [regex]::Replace($Value, '\$\{([A-Za-z0-9_]+)\}', {
            param($Match)
            $name = $Match.Groups[1].Value
            if ($Defines.ContainsKey($name)) {
                return [string] $Defines[$name]
            }

            return $Match.Value
        })
}

function Get-Define {
    param(
        [Parameter(Mandatory = $true)]
        [hashtable] $Defines,

        [Parameter(Mandatory = $true)]
        [string] $Name
    )

    if (-not $Defines.ContainsKey($Name)) {
        throw "Missing required NSIS define: $Name"
    }

    return Expand-NsisValue -Value ([string] $Defines[$Name]) -Defines $Defines
}

function Format-JsonText {
    param(
        [Parameter(Mandatory = $true)]
        [string] $Json
    )

    $builder = [System.Text.StringBuilder]::new()
    $indent = 0
    $inString = $false
    $escaped = $false
    $quote = [char] 34
    $backslash = [char] 92

    foreach ($char in $Json.ToCharArray()) {
        if ($inString) {
            [void] $builder.Append($char)
            if ($escaped) {
                $escaped = $false
            }
            elseif ($char -eq $backslash) {
                $escaped = $true
            }
            elseif ($char -eq $quote) {
                $inString = $false
            }
            continue
        }

        if ($char -eq $quote) {
            $inString = $true
            [void] $builder.Append($char)
        }
        elseif ($char -eq '{' -or $char -eq '[') {
            [void] $builder.Append($char)
            [void] $builder.Append("`n")
            $indent++
            [void] $builder.Append(" " * ($indent * 2))
        }
        elseif ($char -eq '}' -or $char -eq ']') {
            [void] $builder.Append("`n")
            $indent--
            [void] $builder.Append(" " * ($indent * 2))
            [void] $builder.Append($char)
        }
        elseif ($char -eq ',') {
            [void] $builder.Append($char)
            [void] $builder.Append("`n")
            [void] $builder.Append(" " * ($indent * 2))
        }
        elseif ($char -eq ':') {
            [void] $builder.Append(": ")
        }
        elseif (-not [char]::IsWhiteSpace($char)) {
            [void] $builder.Append($char)
        }
    }

    $formatted = $builder.ToString()
    $formatted = $formatted -replace '\\u003c', '<'
    $formatted = $formatted -replace '\\u003e', '>'
    $formatted = $formatted -replace '\\u0026', '&'

    return $formatted
}

function New-ToolEntry {
    param(
        [Parameter(Mandatory = $true)]
        [string] $Id,

        [Parameter(Mandatory = $true)]
        [string] $Name,

        [Parameter(Mandatory = $true)]
        [string] $Version,

        [Parameter(Mandatory = $true)]
        [string] $InstallState,

        [Parameter(Mandatory = $true)]
        [string] $SupportState,

        [Parameter(Mandatory = $true)]
        [string] $ArchiveUrl,

        [Parameter(Mandatory = $true)]
        [string] $Sha256,

        [Parameter(Mandatory = $true)]
        [string] $InstallPath,

        [string] $IconUrl = "",

        [string] $Notes = ""
    )

    return [ordered]@{
        id           = $Id
        name         = $Name
        version      = $Version
        installState = $InstallState
        supportState = $SupportState
        archiveUrl   = $ArchiveUrl
        sha256       = $Sha256
        installPath  = $InstallPath
        iconUrl      = $IconUrl
        notes        = $Notes
    }
}

function Format-ToolIcon {
    param(
        [Parameter(Mandatory = $true)]
        [hashtable] $Tool
    )

    if ([string] $Tool.id -eq "openssh") {
        return [System.Char]::ConvertFromUtf32(0x1F510)
    }

    if ([string]::IsNullOrWhiteSpace([string] $Tool.iconUrl)) {
        return "-"
    }

    return "<img src=""$($Tool.iconUrl)"" width=""18"" height=""18"" alt=""$($Tool.name)"" />"
}

function Format-MarkdownCell {
    param(
        [Parameter(Mandatory = $true)]
        [string] $Value
    )

    return (($Value -replace '\|', '\|') -replace "`r?`n", "<br>")
}

function Format-Code {
    param(
        [Parameter(Mandatory = $true)]
        [string] $Value
    )

    return "``$Value``"
}

function Get-ChangelogRelease {
    param(
        [Parameter(Mandatory = $true)]
        [string] $Path,

        [Parameter(Mandatory = $true)]
        [string] $Version
    )

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        return $null
    }

    $text = [System.IO.File]::ReadAllText($Path, [System.Text.Encoding]::UTF8)
    $versionCandidates = @($Version)
    $versionWithoutBuildMetadata = ($Version -split '\+', 2)[0]
    if ($versionWithoutBuildMetadata -ne $Version) {
        $versionCandidates += $versionWithoutBuildMetadata
    }

    foreach ($candidate in $versionCandidates) {
        $tag = "v$candidate"
        $beginMarker = "<!-- BEGIN RELEASE $tag -->"
        $endMarker = "<!-- END RELEASE $tag -->"
        $beginIndex = $text.IndexOf($beginMarker, [System.StringComparison]::Ordinal)
        $endIndex = $text.IndexOf($endMarker, [System.StringComparison]::Ordinal)

        if ($beginIndex -ge 0 -and $endIndex -gt $beginIndex) {
            $bodyStart = $beginIndex + $beginMarker.Length
            $body = $text.Substring($bodyStart, $endIndex - $bodyStart).Trim()
            $normalizedBody = ($body -replace "`r`n", "`n") -replace "`r", "`n"
            $bodyLines = @($normalizedBody -split "`n")
            $headingIndex = -1
            for ($index = 0; $index -lt $bodyLines.Length; $index++) {
                if ($bodyLines[$index] -match '^\s*##\s+') {
                    $headingIndex = $index
                    break
                }
            }

            if ($headingIndex -ge 0) {
                $bodyLines = @($bodyLines[($headingIndex + 1)..($bodyLines.Length - 1)])
            }

            return [ordered]@{
                version = $candidate
                tag     = $tag
                lines   = $bodyLines
            }
        }
    }

    return $null
}

function Get-ParagraphBeforeHeading {
    param(
        [string[]] $Lines,

        [Parameter(Mandatory = $true)]
        [string] $HeadingPattern
    )

    $paragraphs = New-Object System.Collections.Generic.List[string]
    $currentParagraph = New-Object System.Collections.Generic.List[string]
    function Add-CurrentParagraph {
        if ($currentParagraph.Count -eq 0) {
            return
        }

        $paragraphs.Add(($currentParagraph -join " ").Trim())
        $currentParagraph.Clear()
    }

    foreach ($line in $Lines) {
        if ($line -match $HeadingPattern) {
            break
        }

        if ($line -match '^\s*<!--') {
            continue
        }

        if (-not [string]::IsNullOrWhiteSpace($line)) {
            $currentParagraph.Add($line.Trim())
        }
        else {
            Add-CurrentParagraph
        }
    }

    Add-CurrentParagraph

    return $paragraphs.ToArray()
}

function Get-ListItemsInHeading {
    param(
        [string[]] $Lines,

        [Parameter(Mandatory = $true)]
        [string] $HeadingPattern
    )

    $items = New-Object System.Collections.Generic.List[string]
    $inSection = $false
    $currentItem = ""
    foreach ($line in $Lines) {
        if ($line -match $HeadingPattern) {
            $inSection = $true
            continue
        }

        if ($inSection -and $line -match '^\s*###\s+') {
            if (-not [string]::IsNullOrWhiteSpace($currentItem)) {
                $items.Add($currentItem.Trim())
                $currentItem = ""
            }

            break
        }

        if ($inSection -and $line -match '^\s*-\s+(.+?)\s*$') {
            if (-not [string]::IsNullOrWhiteSpace($currentItem)) {
                $items.Add($currentItem.Trim())
            }

            $currentItem = $Matches[1]
        }
        elseif ($inSection -and $line -match '^\s+(.+?)\s*$' -and -not [string]::IsNullOrWhiteSpace($currentItem)) {
            $currentItem = "$currentItem $($Matches[1].Trim())"
        }
    }

    if (-not [string]::IsNullOrWhiteSpace($currentItem)) {
        $items.Add($currentItem.Trim())
    }

    return $items.ToArray()
}

function Get-ChangelogWhatChangedLines {
    param([string[]] $Lines)

    $output = New-Object System.Collections.Generic.List[string]
    $copy = $false
    foreach ($line in $Lines) {
        if ($line -match '^\s*###\s+.+Features') {
            $copy = $true
        }

        if (-not $copy) {
            continue
        }

        if ($line -match '^\s*###\s+.+Release Assets') {
            break
        }

        if ($line -match '^\s*<!--') {
            continue
        }

        $output.Add($line)
    }

    return $output.ToArray()
}

function Add-ChangelogSection {
    param(
        [System.Collections.Generic.List[string]] $Notes,

        [string[]] $SectionLines
    )

    if ($null -eq $SectionLines -or $SectionLines.Length -eq 0) {
        return
    }

    $Notes.Add("## What's Changed")
    $Notes.Add("")

    foreach ($line in $SectionLines) {
        if ($line -match '^\s*###\s+(.+?)\s*$') {
            $Notes.Add("### $($Matches[1])")
        }
        elseif ($line -match '^\s*-\s+(.+?)\s*$') {
            $Notes.Add("- $($Matches[1])")
        }
        elseif (-not [string]::IsNullOrWhiteSpace($line)) {
            $Notes.Add($line)
        }
        else {
            if ($Notes.Count -eq 0 -or -not [string]::IsNullOrWhiteSpace($Notes[$Notes.Count - 1])) {
                $Notes.Add("")
            }
        }
    }

    if ($Notes.Count -eq 0 -or -not [string]::IsNullOrWhiteSpace($Notes[$Notes.Count - 1])) {
        $Notes.Add("")
    }
}

$configFullPath = Resolve-RepoPath -Path $ConfigPath
if (-not (Test-Path -LiteralPath $configFullPath -PathType Leaf)) {
    throw "Config file not found: $configFullPath"
}

$defines = Get-NsisDefines -Path $configFullPath
$appVersion = Get-Define -Defines $defines -Name "APP_VERSION"

$tools = @(
    New-ToolEntry `
        -Id "vscode" `
        -Name "Visual Studio Code portable" `
        -Version (Get-Define -Defines $defines -Name "VSCODE_VERSION") `
        -InstallState "installable" `
        -SupportState "supported" `
        -ArchiveUrl (Get-Define -Defines $defines -Name "VSCODE_URL") `
        -Sha256 (Get-Define -Defines $defines -Name "VSCODE_SHA256") `
        -InstallPath (Get-Define -Defines $defines -Name "VSCODE_INSTALL_DIR") `
        -IconUrl "https://cdn.jsdelivr.net/gh/devicons/devicon@latest/icons/vscode/vscode-original.svg" `
        -Notes "Installed by the Start and Classroom profiles."

    New-ToolEntry `
        -Id "git" `
        -Name "Git for Windows portable" `
        -Version (Get-Define -Defines $defines -Name "GIT_VERSION") `
        -InstallState "installable" `
        -SupportState "supported" `
        -ArchiveUrl (Get-Define -Defines $defines -Name "GIT_URL") `
        -Sha256 (Get-Define -Defines $defines -Name "GIT_SHA256") `
        -InstallPath (Get-Define -Defines $defines -Name "GIT_INSTALL_DIR") `
        -IconUrl "https://cdn.jsdelivr.net/gh/devicons/devicon@latest/icons/git/git-original.svg" `
        -Notes "Installed by the Classroom profile."

    New-ToolEntry `
        -Id "xampp" `
        -Name "XAMPP portable" `
        -Version (Get-Define -Defines $defines -Name "XAMPP_VERSION") `
        -InstallState "installable" `
        -SupportState "supported" `
        -ArchiveUrl (Get-Define -Defines $defines -Name "XAMPP_URL") `
        -Sha256 (Get-Define -Defines $defines -Name "XAMPP_SHA256") `
        -InstallPath (Get-Define -Defines $defines -Name "XAMPP_INSTALL_DIR") `
        -IconUrl "https://cdn.simpleicons.org/xampp/FB7A24" `
        -Notes "Installed by the Classroom profile; includes Codex 13 path and PHP extension diagnostics."

    New-ToolEntry `
        -Id "openssh" `
        -Name "OpenSSH for Windows portable" `
        -Version (Get-Define -Defines $defines -Name "OPENSSH_VERSION") `
        -InstallState "hidden" `
        -SupportState "experimental" `
        -ArchiveUrl (Get-Define -Defines $defines -Name "OPENSSH_URL") `
        -Sha256 (Get-Define -Defines $defines -Name "OPENSSH_SHA256") `
        -InstallPath (Get-Define -Defines $defines -Name "OPENSSH_INSTALL_DIR") `
        -Notes "Metadata and pinned downloads are present, but the component is not exposed in this alpha release."
)

$releaseAssetBaseName = "codex13-sdk_$BuildVersion`_windows_x64_setup.exe"
$releaseChecksumsFileName = "codex13-sdk_$BuildVersion`_checksums.txt"
$releaseManifestFileName = "codex13-sdk_$BuildVersion`_release_manifest.json"
$releaseNotesFileName = "codex13-sdk_$BuildVersion`_release_notes.md"

if ([string]::IsNullOrWhiteSpace($OutputPath)) {
    $OutputPath = "dist/setup/$releaseManifestFileName"
}

if ([string]::IsNullOrWhiteSpace($ReleaseNotesPath)) {
    $ReleaseNotesPath = "dist/setup/$releaseNotesFileName"
}

$manifest = [ordered]@{
    schemaVersion = 1
    manifestName  = [System.IO.Path]::GetFileName($OutputPath)
    product       = "Codex 13 Student Dev Kit"
    appVersion    = $appVersion
    buildVersion  = $BuildVersion
    generatedAt   = (Get-Date).ToUniversalTime().ToString("o")
    releaseLine   = "$appVersion-alpha.<build_number>"
    installer     = [ordered]@{
        fileName = $releaseAssetBaseName
        channel  = "release"
        platform = "win-x64"
        profiles = @(
            [ordered]@{
                id     = "start"
                name   = "Start"
                preset = "clean-vscode"
                tools  = @("vscode")
                status = "installable"
                notes  = "Portable Visual Studio Code profile for the smallest setup."
            },
            [ordered]@{
                id     = "classroom"
                name   = "Classroom"
                preset = "php-mysql-classroom"
                tools  = @("vscode", "git", "xampp")
                status = "installable"
                notes  = "Full PHP and MySQL classroom profile."
            }
        )
    }
    checksums     = [ordered]@{
        fileName  = $releaseChecksumsFileName
        algorithm = "SHA256"
    }
    assets        = @(
        [ordered]@{
            fileName    = $releaseAssetBaseName
            label       = "Codex 13 Student Dev Kit Setup for Windows x64"
            category    = "Windows x64 installer"
            description = "Installs Codex 13 Student Dev Kit under %LOCALAPPDATA%\Codex13\StudentDevKit."
            type        = "installer"
        },
        [ordered]@{
            fileName    = $releaseChecksumsFileName
            label       = "SHA256 checksums for release assets"
            category    = "SHA256 checksums"
            description = "One checksum file covering every release asset."
            type        = "checksums"
        },
        [ordered]@{
            fileName    = $releaseManifestFileName
            label       = "Codex 13 SDK release manifest"
            category    = "Release manifest"
            description = "Machine-readable profiles, tools, pinned URLs, hashes and asset metadata."
            type        = "manifest"
        }
    )
    tools         = $tools
}

$outputFullPath = Resolve-RepoPath -Path $OutputPath
$notesFullPath = Resolve-RepoPath -Path $ReleaseNotesPath
New-Item -ItemType Directory -Force -Path (Split-Path -Parent $outputFullPath) | Out-Null
New-Item -ItemType Directory -Force -Path (Split-Path -Parent $notesFullPath) | Out-Null

$json = Format-JsonText -Json ($manifest | ConvertTo-Json -Depth 10 -Compress)
[System.IO.File]::WriteAllText($outputFullPath, $json + "`n", [System.Text.UTF8Encoding]::new($false))

$generatedNotesFullPath = ""
if (-not [string]::IsNullOrWhiteSpace($GeneratedNotesPath)) {
    $generatedNotesFullPath = Resolve-RepoPath -Path $GeneratedNotesPath
}

$sourceChangelogPath = Join-Path $Root "CHANGELOG.md"
$changelogFullPath = ""
if (-not [string]::IsNullOrWhiteSpace($ChangelogOutputPath)) {
    $changelogFullPath = Resolve-RepoPath -Path $ChangelogOutputPath
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $changelogFullPath) | Out-Null

    if (-not [string]::IsNullOrWhiteSpace($generatedNotesFullPath) -and (Test-Path -LiteralPath $generatedNotesFullPath -PathType Leaf)) {
        Copy-Item -LiteralPath $generatedNotesFullPath -Destination $changelogFullPath -Force
    }
    elseif (Test-Path -LiteralPath $sourceChangelogPath -PathType Leaf) {
        Copy-Item -LiteralPath $sourceChangelogPath -Destination $changelogFullPath -Force
    }
}

$changelogRelease = Get-ChangelogRelease -Path $sourceChangelogPath -Version $BuildVersion
$changelogLines = if ($null -ne $changelogRelease) { [string[]] $changelogRelease.lines } else { @() }
$releaseDescription = @(Get-ParagraphBeforeHeading -Lines $changelogLines -HeadingPattern '^\s*###\s+.+Highlights')
$releaseHighlights = @(Get-ListItemsInHeading -Lines $changelogLines -HeadingPattern '^\s*###\s+.+Highlights')
$whatChangedLines = @(Get-ChangelogWhatChangedLines -Lines $changelogLines)

$toolsById = @{}
foreach ($tool in $manifest.tools) {
    $toolsById[[string] $tool.id] = $tool
}

$notes = New-Object System.Collections.Generic.List[string]
if ($releaseDescription.Count -gt 0) {
    foreach ($line in $releaseDescription) {
        $notes.Add($line)
    }
}
else {
    $notes.Add("A portable Windows classroom development kit installer for Visual Studio Code, Git and XAMPP.")
    $notes.Add("")
    $notes.Add("This alpha build is intended for release validation and early classroom testing. Public builds stay on the ``$appVersion-alpha.<build_number>`` line while installer signing and update hardening continue.")
}
$notes.Add("")
$notes.Add("## Highlights")
$notes.Add("")
if ($releaseHighlights.Count -gt 0) {
    foreach ($highlight in $releaseHighlights) {
        $notes.Add("- $highlight")
    }
}
else {
    $notes.Add("- Installs into ``%LOCALAPPDATA%\Codex13\StudentDevKit`` without administrator rights.")
    $notes.Add("- Keeps the active alpha experience focused on ``Start`` and ``Classroom`` profiles.")
    $notes.Add("- Uses pinned downloads and SHA256 checks for every bundled tool.")
    $notes.Add("- Writes an installation manifest for future Manager and diagnostics workflows.")
}
$notes.Add("")
$notes.Add("## Setup Profiles")
$notes.Add("")
$notes.Add("| Profile | Preset | Included tools | Status | Notes |")
$notes.Add("| --- | --- | --- | --- | --- |")
foreach ($installerProfile in $manifest.installer.profiles) {
    $profileTools = foreach ($toolId in $installerProfile.tools) {
        if ($toolsById.ContainsKey([string] $toolId)) {
            [string] $toolsById[[string] $toolId].name
        }
    }

    $notes.Add("| $($installerProfile.name) | $(Format-Code -Value ([string] $installerProfile.preset)) | $(Format-MarkdownCell -Value ($profileTools -join ", ")) | $($installerProfile.status) | $(Format-MarkdownCell -Value ([string] $installerProfile.notes)) |")
}
$notes.Add("")
$notes.Add("## Included Tools")
$notes.Add("")
$notes.Add("| Icon | Tool | Version | State | Support | Notes |")
$notes.Add("| --- | --- | ---: | --- | --- | --- |")
foreach ($tool in $manifest.tools) {
    $notes.Add("| $(Format-ToolIcon -Tool $tool) | $($tool.name) | $(Format-Code -Value ([string] $tool.version)) | $($tool.installState) | $($tool.supportState) | $(Format-MarkdownCell -Value ([string] $tool.notes)) |")
}
$notes.Add("")
$notes.Add("## Release Assets")
$notes.Add("")
$notes.Add("| File | Type | Description |")
$notes.Add("| --- | --- | --- |")
foreach ($asset in $manifest.assets) {
    $notes.Add("| $(Format-Code -Value ([string] $asset.fileName)) | $($asset.category) | $(Format-MarkdownCell -Value ([string] $asset.description)) |")
}
$notes.Add("")
$notes.Add("## Verification Notes")
$notes.Add("")
$notes.Add("- Installer signing is disabled unless production signing is explicitly enabled for the release run.")
$notes.Add("- ``$releaseChecksumsFileName`` contains SHA256 hashes for the installer and release manifest.")
$notes.Add("- ``$releaseManifestFileName`` records the product version, build version, setup profiles, tools, pinned URLs and source hashes.")
$notes.Add("")
if ($whatChangedLines.Count -gt 0) {
    Add-ChangelogSection -Notes $notes -SectionLines $whatChangedLines
}
elseif (-not [string]::IsNullOrWhiteSpace($generatedNotesFullPath) -and (Test-Path -LiteralPath $generatedNotesFullPath -PathType Leaf)) {
    $notes.AddRange([string[]] (Get-Content -LiteralPath $generatedNotesFullPath))
    $notes.Add("")
}

if ($null -ne $changelogRelease) {
    $changelogTag = [string] $changelogRelease["tag"]
    if ($notes.Count -gt 0 -and [string]::IsNullOrWhiteSpace($notes[$notes.Count - 1])) {
        $notes.RemoveAt($notes.Count - 1)
    }

    $notes.Add("")
    $notes.Add("Repository changelog source: ``CHANGELOG.md`` entry ``$changelogTag``.")
}

$normalizedNotes = New-Object System.Collections.Generic.List[string]
foreach ($line in $notes) {
    if ([string]::IsNullOrWhiteSpace($line)) {
        if ($normalizedNotes.Count -eq 0 -or [string]::IsNullOrWhiteSpace($normalizedNotes[$normalizedNotes.Count - 1])) {
            continue
        }
    }

    $normalizedNotes.Add($line)
}

while ($normalizedNotes.Count -gt 0 -and [string]::IsNullOrWhiteSpace($normalizedNotes[$normalizedNotes.Count - 1])) {
    $normalizedNotes.RemoveAt($normalizedNotes.Count - 1)
}

[System.IO.File]::WriteAllText($notesFullPath, (($normalizedNotes -join "`n") + "`n"), [System.Text.UTF8Encoding]::new($false))

Write-Host "Release manifest written: $outputFullPath"
Write-Host "Release notes written: $notesFullPath"
if (-not [string]::IsNullOrWhiteSpace($changelogFullPath)) {
    Write-Host "Release changelog written: $changelogFullPath"
}
