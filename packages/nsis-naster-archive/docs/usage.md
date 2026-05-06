# Usage

## Extract An Archive

`nasterarchive::extract` extracts an archive into a destination directory using
the `7za.exe` path supplied by the installer.

```nsis
nasterarchive::extract \
  /NSISDL \
  /7ZIP "$SevenZipPath" \
  /CAPTION "Extracting package" \
  /TEXT "Extracting package... please wait." \
  "$ArchivePath" \
  "$DestinationDir" \
  /END
Pop $0
```

The command is synchronous from the NSIS script point of view. It returns after
the extraction worker exits or after the user cancels the operation.

`/NSISDL` enables embedded progress UI on the install files page. Without it,
the command runs synchronously without creating plug-in UI.

## Excluding Paths

Pass `/EXCLUDE` more than once to forward multiple exclude patterns to 7-Zip:

```nsis
nasterarchive::extract \
  /NSISDL \
  /7ZIP "$SevenZipPath" \
  /EXCLUDE "xampp\htdocs" \
  /EXCLUDE "xampp\htdocs\*" \
  "$CacheDir\xampp.zip" \
  "$INSTDIR\tools" \
  /END
Pop $0
```

## Behavior Outside the InstFiles Page

`/NSISDL` embeds the progress dialog on the install files page. If `extract` is
called from a different page (or a custom page where the inner dialog cannot be
located), `/NSISDL` has no effect: no progress UI appears, cancel is not
available, and the extraction runs silently until it finishes. The return value
is still pushed onto the NSIS stack normally.

## Result Handling

```nsis
Pop $0
${If} $0 == "OK"
  DetailPrint "Archive extracted."
${ElseIf} $0 == "cancel"
  DetailPrint "Extraction cancelled."
${Else}
  DetailPrint "Extraction failed: $0"
${EndIf}
```
