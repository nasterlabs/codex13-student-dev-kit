Unicode true
OutFile "nasterarchive-extract-basic.exe"
RequestExecutionLevel user

!addplugindir "..\..\dist\nsis-naster-archive\plugins\x86-unicode"

Section
  nasterarchive::extract \
    /NSISDL \
    /7ZIP "$EXEDIR\7za.exe" \
    /CAPTION "Extracting sample archive" \
    /TEXT "Extracting sample archive... please wait." \
    /CANCELTEXT "Cancel" \
    /QUESTION "Cancel extraction?" \
    "$EXEDIR\sample.zip" \
    "$EXEDIR\sample-output" \
    /END
  Pop $0

  DetailPrint "nasterarchive result: $0"
SectionEnd
