/* Check if LoadRTFincluded is defined so that LoadRTF can't be included twice */
!ifndef LoadRTFincluded

/*
    Defines used by LoadRTF
*/
!ifndef SF_RTF
    !define SF_RTF 2
!endif
!ifndef EM_STREAMIN
    !define EM_STREAMIN 1097
!endif
!ifndef EM_EXLIMITTEXT
    !define EM_EXLIMITTEXT 1077
!endif

/*
    LoadRTF Main Function
    Inserted via macro for Installer vs Uninstaller

    Loads an RTF file into a RichEdit20A/W control.

    Source: https://nsis.sourceforge.io/LoadRTF
*/
!macro LoadRTFfunc Un
Function ${Un}LoadRTF
                            ; RichEdit20A.hwnd RTFilePath.string
    Exch $0                 ; $0 RTFilePath.string                  ; $0 = RichEdit20A.hwnd
    Exch                    ; RTFilePath.string $0
    Exch $1                 ; $1 $0                                 ; $1 = RTFilePath.string
    Push $2                 ; $2 $1 $0                              ; $2 : Callback address
    Push $3                 ; $3 $2 $1 $0                           ; $3 : EDITSTREAM structure
    Push $4                 ; $4 $3 $2 $1 $0                        ; $4 : callbackN identifier from System plugin to check against
    Push $R0                ; $R0 $4 $3 $2 $1 $0                    ; $R0 : Buffer that receives data from ReadFile()
    Push $R1                ; $R1 $R0 $4 $3 $@ $1 $0                ; $R1 : Maximum number of bytes to read using ReadFile()
    Push $R2                ; $R2 $R1 $R0 $4 $3 $@ $1 $0            ; $R2 : Number of bytes actually read using ReadFile()

    SendMessage $0 ${EM_EXLIMITTEXT} 0 0x7fffffff

    System::Get "(i, i .R0, i .R1, i .R2) iss"
    Pop $2

    System::Call "*(i 0, i 0, k r2) i .r3"
    System::Call "user32::SendMessage(i r0, i ${EM_STREAMIN}, i ${SF_RTF}, i r3) i.s"
    Pop $4
    Push $4

    ClearErrors
    FileOpen $1 "$1" r
    _loop:
        Pop $0
        StrCmp $0 "$4" 0 _done
        System::Call "kernel32::ReadFile(i $1, i $R0, i $R1, i $R2, i 0)"
        Push 0
        System::Call "$2"
        goto _loop
    _done:
    FileClose $1
    System::Free $3
    System::Free $2

    Pop $R2
    Pop $R1
    Pop $R0
    Pop $4
    Pop $3
    Pop $2
    Pop $1
    Pop $0
FunctionEnd
!macroend
!insertmacro LoadRTFfunc ""
!ifdef LOADRTF_INCLUDE_UNINSTALLER
!insertmacro LoadRTFfunc "un."
!endif

/*
    LoadRTF Ease of use functions.
*/
!macro LoadRTF file hwnd
    Push "${file}"
    Push ${hwnd}
    Call LoadRTF
!macroend
!define LoadRTF `!insertmacro LoadRTF`

!ifdef LOADRTF_INCLUDE_UNINSTALLER
!macro un.LoadRTF file hwnd
    Push "${file}"
    Push ${hwnd}
    Call un.LoadRTF
!macroend
!define un.LoadRTF `!insertmacro un.LoadRTF`
!endif

!define LoadRTFincluded

!endif
