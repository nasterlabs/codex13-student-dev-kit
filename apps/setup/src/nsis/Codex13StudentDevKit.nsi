Unicode true

!include "MUI2.nsh"
!include "FileFunc.nsh"
!include "LogicLib.nsh"
!include "Sections.nsh"
!include "nsDialogs.nsh"
!include "WinMessages.nsh"
!include "WordFunc.nsh"
!include "include\LoadRTF.nsh"
!include "config.nsh"

!insertmacro WordReplace

Name "${APP_NAME}"
!ifndef APP_OUTPUT_PATH
!define APP_OUTPUT_PATH "..\..\..\..\dist\setup\${APP_EXE_NAME}"
!endif
OutFile "${APP_OUTPUT_PATH}"
InstallDir "${DEFAULT_INSTALL_DIR}"
InstallDirRegKey HKCU "${APP_SETTINGS_REG_KEY}" "InstallDir"
RequestExecutionLevel user

BrandingText "© 2026 Naster Labs (Luczak Consulting P.S.A.)"
ManifestSupportedOS Win10

VIProductVersion "${APP_VERSION_QUAD}"
VIAddVersionKey /LANG=${LANG_VERSION_POLISH} "ProductName" "${APP_NAME}"
VIAddVersionKey /LANG=${LANG_VERSION_POLISH} "CompanyName" "${APP_PUBLISHER}"
VIAddVersionKey /LANG=${LANG_VERSION_POLISH} "FileDescription" "${APP_FILE_DESCRIPTION_PL}"
VIAddVersionKey /LANG=${LANG_VERSION_POLISH} "FileVersion" "${BUILD_VERSION}"
VIAddVersionKey /LANG=${LANG_VERSION_POLISH} "ProductVersion" "${BUILD_VERSION}"
VIAddVersionKey /LANG=${LANG_VERSION_POLISH} "InternalName" "${APP_INTERNAL_NAME}"
VIAddVersionKey /LANG=${LANG_VERSION_POLISH} "OriginalFilename" "${APP_EXE_NAME}"
VIAddVersionKey /LANG=${LANG_VERSION_POLISH} "LegalCopyright" "${APP_COPYRIGHT_PL}"
VIAddVersionKey /LANG=${LANG_VERSION_POLISH} "LegalTrademarks" "${APP_TRADEMARKS_PL}"
VIAddVersionKey /LANG=${LANG_VERSION_POLISH} "Comments" "${APP_DESCRIPTION_PL}"
VIAddVersionKey /LANG=${LANG_VERSION_POLISH} "Website" "${APP_WEBSITE}"
VIAddVersionKey /LANG=${LANG_VERSION_ENGLISH} "ProductName" "${APP_NAME}"
VIAddVersionKey /LANG=${LANG_VERSION_ENGLISH} "CompanyName" "${APP_PUBLISHER}"
VIAddVersionKey /LANG=${LANG_VERSION_ENGLISH} "FileDescription" "${APP_FILE_DESCRIPTION_EN}"
VIAddVersionKey /LANG=${LANG_VERSION_ENGLISH} "FileVersion" "${BUILD_VERSION}"
VIAddVersionKey /LANG=${LANG_VERSION_ENGLISH} "ProductVersion" "${BUILD_VERSION}"
VIAddVersionKey /LANG=${LANG_VERSION_ENGLISH} "InternalName" "${APP_INTERNAL_NAME}"
VIAddVersionKey /LANG=${LANG_VERSION_ENGLISH} "OriginalFilename" "${APP_EXE_NAME}"
VIAddVersionKey /LANG=${LANG_VERSION_ENGLISH} "LegalCopyright" "${APP_COPYRIGHT_EN}"
VIAddVersionKey /LANG=${LANG_VERSION_ENGLISH} "LegalTrademarks" "${APP_TRADEMARKS_EN}"
VIAddVersionKey /LANG=${LANG_VERSION_ENGLISH} "Comments" "${APP_DESCRIPTION_EN}"
VIAddVersionKey /LANG=${LANG_VERSION_ENGLISH} "Website" "${APP_WEBSITE}"
!if "${BUILD_CHANNEL}" != "release"
VIAddVersionKey /LANG=${LANG_VERSION_POLISH} "PrivateBuild" "${APP_PRIVATE_BUILD_PL}"
VIAddVersionKey /LANG=${LANG_VERSION_POLISH} "SpecialBuild" "${APP_SPECIAL_BUILD_PL}"
VIAddVersionKey /LANG=${LANG_VERSION_ENGLISH} "PrivateBuild" "${APP_PRIVATE_BUILD_EN}"
VIAddVersionKey /LANG=${LANG_VERSION_ENGLISH} "SpecialBuild" "${APP_SPECIAL_BUILD_EN}"
!endif

!define MUI_ABORTWARNING
!define MUI_CUSTOMFUNCTION_ABORT OnUserAbort
!define MUI_INSTFILESPAGE_PROGRESSBAR ""
!define MUI_FINISHPAGE_NOAUTOCLOSE
!define MUI_ICON "..\..\assets\nsis\codex13-favicon.ico"
!define MUI_UNICON "..\..\assets\nsis\codex13-favicon.ico"
!define MUI_HEADERIMAGE
!define MUI_HEADERIMAGE_RIGHT
!define MUI_HEADERIMAGE_BITMAP "..\..\assets\nsis\codex13-header.bmp"
!define MUI_HEADERIMAGE_UNBITMAP "..\..\assets\nsis\codex13-header.bmp"
!define MUI_WELCOMEFINISHPAGE_BITMAP "..\..\assets\nsis\codex13-wizard.bmp"
!define MUI_UNWELCOMEFINISHPAGE_BITMAP "..\..\assets\nsis\codex13-wizard.bmp"
!define MUI_WELCOMEPAGE_TITLE "$(C13_WELCOME_TITLE)"
!define MUI_WELCOMEPAGE_TEXT "$(C13_WELCOME_TEXT)"
!define MUI_FINISHPAGE_TITLE "$(C13_FINISH_TITLE)"
!define MUI_FINISHPAGE_TEXT "$(C13_FINISH_TEXT)"
!define MUI_FINISHPAGE_RUN
!define MUI_FINISHPAGE_RUN_TEXT "$(C13_FINISH_RUN)"
!define MUI_FINISHPAGE_RUN_FUNCTION FinishRunLauncher
!define MUI_FINISHPAGE_SHOWREADME "$INSTDIR"
!define MUI_FINISHPAGE_SHOWREADME_TEXT "$(C13_FINISH_OPEN_INSTALL_DIR)"
!define MUI_FINISHPAGE_SHOWREADME_NOTCHECKED
!define MUI_DIRECTORYPAGE_TEXT_TOP "$(C13_DIRECTORY_TEXT_TOP)"
!define MUI_LANGDLL_REGISTRY_ROOT "HKCU"
!define MUI_LANGDLL_REGISTRY_KEY "${APP_SETTINGS_REG_KEY}"
!define MUI_LANGDLL_REGISTRY_VALUENAME "InstallerLanguage"
!define MUI_LANGDLL_ALLLANGUAGES
!define UNINSTALL_REG_KEY "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_REGISTRY_KEY}"

Var CacheDir
Var StartMenuDir
Var StartMenuFolder
Var VerifyScriptPath
Var ManifestScriptPath
Var SevenZipPath
Var OfflinePackageDir
Var XamppPatchDeleteListPath
Var XamppPatchCommandListPath
Var XamppPatchValidationListPath
Var InstallHadErrors
Var InstallLogPath
Var PackageReady
Var MaintenanceMode
Var MaintenanceReinstallRadio
Var MaintenanceRepairRadio
Var MaintenanceRemoveRadio
Var RemoveExistingVsCode
Var RemoveExistingXampp
Var PreserveVsCodeData
Var PreserveXamppData
Var TermsCheckLicense
Var TermsCheckExternal
Var TermsCheckPrivacy
Var TermsRtfPath
Var TermsRichEdit
Var ProfileId
Var ProfileMinimalRadio
Var ProfileWebRadio
Var ProfileLabRadio
Var ProfileCustomRadio
Var PresetId
Var PresetRadio1
Var PresetRadio2
Var PresetRadio3
Var PresetLabel1
Var PresetLabel2
Var PresetLabel3
Var PresetPlannedLabel1
Var PresetPlannedLabel2
Var PresetPlannedLabel3
Var VscodeProfile
Var VscodeNoneRadio
Var VscodePortableData
Var VscodeGitPath
Var VscodeExtensions
Var AdvancedForceDownload
Var AdvancedShowDetails
Var AdvancedForceDownloadCheckbox
Var AdvancedShowDetailsCheckbox
Var UnattendedEnabled
Var UnattendedFilePath
Var UnattendedSilentRequested
Var SummaryText

Var SummaryInstallDirRtf
Var SummaryRtfPath
Var EstimatedSizeKb
Var EstimatedSizeMb
Var ExistingVsCodeCheckbox
Var ExistingVsCodeDataOnly
Var ExistingXamppSkipRadio
Var ExistingXamppPreserveRadio
Var ExistingXamppRemoveRadio
Var ExistingXamppDataOnly
; Var ComponentVscodeCheckbox
; Var ComponentGitCheckbox
; Var ComponentOpenSshCheckbox
; Var ComponentXamppCheckbox
; Var DesktopLauncherCheckbox
; Var DesktopVscodeCheckbox
; Var DesktopGitBashCheckbox
; Var DesktopGitCmdCheckbox
; Var DesktopXamppCheckbox
; Var ComponentDescriptionText
Var UnRemoveCache
Var UnRemoveCacheCheckbox
Var UnRemoveLogs
Var UnRemoveLogsCheckbox
Var UnRemoveInstallDir
Var UnRemoveInstallDirCheckbox
Var UnRemoveStartMenu
Var UnRemoveDesktop
Var UnRemoveLaunchers
Var UnRemoveVsCodeData
Var UnRemoveVsCodeDataCheckbox
Var UnRemoveXamppHtdocs
Var UnRemoveXamppHtdocsCheckbox
Var UnRemoveXamppMysqlData
Var UnRemoveXamppMysqlDataCheckbox
; Var UnRemoveOpenSshKeys
; Var UnRemoveOpenSshKeysCheckbox

; ── DEBUG TRACE ──────────────────────────────────────────────────────────────
; Enable at build time: set C13_DEBUG_LOG_ENABLED=1 in .env.
; Override log path:    set C13_DEBUG_LOG_FILE=C:\path\to\log.txt in .env.
!ifdef C13_DEBUG_LOG_ENABLED
  !ifndef C13_DBG_LOG
    !define C13_DBG_LOG "$EXEDIR\c13sdk-debug.log"
  !endif
  !macro _C13_DbgLog msg
      Push $R9
      FileOpen $R9 "${C13_DBG_LOG}" a
      FileSeek $R9 0 END
      FileWrite $R9 "${msg}$\r$\n"
      FileClose $R9
      Pop $R9
  !macroend
!else
  !macro _C13_DbgLog msg
  !macroend
!endif
!define C13_DbgLog "!insertmacro _C13_DbgLog"
; ─────────────────────────────────────────────────────────────────────────────

!macro LogLine LEVEL MESSAGE
    ${If} $InstallLogPath != ""
        Push $R0
        Push $R1
        Push $R2
        Push $R3
        Push $R4
        Push $R5
        Push $R6
        Push $R8
        ${GetTime} "" "L" $R0 $R1 $R2 $R3 $R4 $R5 $R6
        FileOpen $R8 "$InstallLogPath" a
        ${If} $R8 != ""
            FileSeek $R8 0 END
            FileWrite $R8 "[$R2-$R1-$R0 $R4:$R5:$R6] [${LEVEL}] ${MESSAGE}$\r$\n"
            FileClose $R8
        ${EndIf}
        Pop $R8
        Pop $R6
        Pop $R5
        Pop $R4
        Pop $R3
        Pop $R2
        Pop $R1
        Pop $R0
    ${EndIf}
!macroend

!macro QuietRMDir PATH
    SetDetailsPrint none
    RMDir /r "${PATH}"
    SetDetailsPrint both
!macroend

!macro QuietDelete PATH
    SetDetailsPrint none
    Delete "${PATH}"
    SetDetailsPrint both
!macroend

!macro DownloadPackage DISPLAY_NAME URL ARCHIVE_NAME DONE_LABEL
    DetailPrint "$(C13_DOWNLOADING_PREFIX) ${DISPLAY_NAME}..."
    !insertmacro LogLine "INFO" "Downloading ${DISPLAY_NAME}..."
    inetc::get \
        /CAPTION "$(C13_DOWNLOADING_PREFIX) ${DISPLAY_NAME}" \
        /CANCELTEXT "$(C13_CANCEL)" \
        /QUESTION "$(C13_DOWNLOAD_ABORT_QUESTION)" \
        /TRANSLATE \
            "$(C13_DOWNLOADING_PREFIX) %s" \
            "$(C13_DOWNLOAD_CONNECTING)" \
            "$(C13_DOWNLOAD_SECONDS)" \
            "$(C13_DOWNLOAD_MINUTES)" \
            "$(C13_DOWNLOAD_HOURS)" \
            "y" \
            "%dkB (%d%%) z %dkB @ %d.%01dkB/s " \
            "$(C13_DOWNLOAD_REMAINING)" \
        "${URL}" "$CacheDir\${ARCHIVE_NAME}" \
        /END
    Pop $0

    ${If} $0 != "OK"
        StrCpy $InstallHadErrors "1"
        DetailPrint "$(C13_ERROR_PREFIX) $(C13_DOWNLOAD_FAILED_PREFIX) ${DISPLAY_NAME}: $0"
        !insertmacro LogLine "ERROR" "Failed to download ${DISPLAY_NAME}: $0"
        MessageBox MB_ICONEXCLAMATION "$(C13_DOWNLOAD_FAILED_PREFIX) ${DISPLAY_NAME}.$\r$\n$(C13_DETAILS): $0"
        Goto ${DONE_LABEL}
    ${EndIf}
    !insertmacro LogLine "OK" "${DISPLAY_NAME} downloaded."
!macroend

!macro VerifyPackage DISPLAY_NAME ARCHIVE_NAME EXPECTED_SHA256 DONE_LABEL
    DetailPrint "$(C13_VERIFYING_PACKAGE_PREFIX) ${DISPLAY_NAME}..."
    !insertmacro LogLine "INFO" "Checking package ${DISPLAY_NAME}..."
    nsExec::ExecToStack '"$SYSDIR\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "$VerifyScriptPath" -ArchivePath "$CacheDir\${ARCHIVE_NAME}" -ExpectedSha256 "${EXPECTED_SHA256}"'
    Pop $0
    Pop $1

    ${If} $0 != "0"
        StrCpy $InstallHadErrors "1"
        DetailPrint "$(C13_ERROR_PREFIX) $(C13_PACKAGE_DAMAGED_PREFIX) ${DISPLAY_NAME} $(C13_DETAIL_VERIFICATION_FAILED)"
        DetailPrint "$1"
        !insertmacro LogLine "ERROR" "Package ${DISPLAY_NAME} failed verification."
        !insertmacro LogLine "ERROR" "$1"
        MessageBox MB_ICONEXCLAMATION "$(C13_PACKAGE_DAMAGED_PREFIX) ${DISPLAY_NAME} $(C13_PACKAGE_DAMAGED_SUFFIX)"
        Delete "$CacheDir\${ARCHIVE_NAME}"
        Goto ${DONE_LABEL}
    ${EndIf}
    !insertmacro LogLine "OK" "${DISPLAY_NAME} verified."
!macroend

!macro PreparePackage DISPLAY_NAME URL ARCHIVE_NAME EXPECTED_SHA256 DONE_LABEL
    StrCpy $PackageReady "0"

    ${If} $AdvancedForceDownload == "1"
        DetailPrint "$(C13_FORCE_DOWNLOAD_PREFIX) ${DISPLAY_NAME}. $(C13_SKIP_CACHE)"
        !insertmacro LogLine "INFO" "Forced re-download for ${DISPLAY_NAME}; skipping cache."
        Delete "$CacheDir\${ARCHIVE_NAME}"
    ${EndIf}

    ${If} ${FileExists} "$CacheDir\${ARCHIVE_NAME}"
        DetailPrint "$(C13_FOUND_LOCAL_PACKAGE_PREFIX) ${DISPLAY_NAME}. $(C13_CHECKING_SUFFIX)"
        !insertmacro LogLine "INFO" "Cache ${DISPLAY_NAME}: $CacheDir\${ARCHIVE_NAME}"
        !insertmacro LogLine "INFO" "Expected SHA256 ${DISPLAY_NAME}: ${EXPECTED_SHA256}"
        nsExec::ExecToStack '"$SYSDIR\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "$VerifyScriptPath" -ArchivePath "$CacheDir\${ARCHIVE_NAME}" -ExpectedSha256 "${EXPECTED_SHA256}"'
        Pop $0
        Pop $1

        ${If} $0 == "0"
            DetailPrint "$(C13_USING_EXISTING_PACKAGE_PREFIX) ${DISPLAY_NAME}."
            !insertmacro LogLine "OK" "Using existing ${DISPLAY_NAME} package from packages."
            StrCpy $PackageReady "1"
        ${Else}
            DetailPrint "$(C13_LOCAL_PACKAGE_INVALID_PREFIX) ${DISPLAY_NAME} $(C13_PACKAGE_INVALID_REDOWNLOAD)"
            DetailPrint "$1"
            !insertmacro LogLine "WARN" "Local ${DISPLAY_NAME} package is invalid. Downloading again."
            !insertmacro LogLine "WARN" "$1"
            Delete "$CacheDir\${ARCHIVE_NAME}"
        ${EndIf}
    ${EndIf}

    ${If} $PackageReady != "1"
    ${AndIf} ${FileExists} "$OfflinePackageDir\${ARCHIVE_NAME}"
        DetailPrint "$(C13_FOUND_OFFLINE_PACKAGE_PREFIX) ${DISPLAY_NAME} $(C13_NEXT_TO_INSTALLER_SUFFIX)"
        nsExec::ExecToStack '"$SYSDIR\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "$VerifyScriptPath" -ArchivePath "$OfflinePackageDir\${ARCHIVE_NAME}" -ExpectedSha256 "${EXPECTED_SHA256}"'
        Pop $0
        Pop $1

        ${If} $0 == "0"
            DetailPrint "$(C13_USING_PACKAGE_FROM_DIR_PREFIX) ${DISPLAY_NAME} $(C13_FROM_DIR_SUFFIX) $OfflinePackageDir"
            !insertmacro LogLine "OK" "Using ${DISPLAY_NAME} package from installer-adjacent folder: $OfflinePackageDir"
            CopyFiles /SILENT "$OfflinePackageDir\${ARCHIVE_NAME}" "$CacheDir\${ARCHIVE_NAME}"
            ${If} ${FileExists} "$CacheDir\${ARCHIVE_NAME}"
                StrCpy $PackageReady "1"
            ${Else}
                DetailPrint "$(C13_WARNING_PREFIX) $(C13_COPY_CACHE_FAILED_PREFIX) ${DISPLAY_NAME} $(C13_DOWNLOAD_STANDARD)"
                !insertmacro LogLine "WARN" "Could not copy ${DISPLAY_NAME} package to packages. Downloading normally."
            ${EndIf}
        ${Else}
            DetailPrint "$(C13_PACKAGE_DAMAGED_PREFIX) ${DISPLAY_NAME} $(C13_OFFLINE_PACKAGE_INVALID_SUFFIX)"
            DetailPrint "$1"
            !insertmacro LogLine "WARN" "Installer-adjacent ${DISPLAY_NAME} package is invalid. Skipping it."
            !insertmacro LogLine "WARN" "$1"
        ${EndIf}
    ${EndIf}

    ${If} $PackageReady != "1"
        !insertmacro DownloadPackage "${DISPLAY_NAME}" "${URL}" "${ARCHIVE_NAME}" "${DONE_LABEL}"
        !insertmacro VerifyPackage "${DISPLAY_NAME}" "${ARCHIVE_NAME}" "${EXPECTED_SHA256}" "${DONE_LABEL}"
    ${EndIf}
!macroend

!macro CreateToolShortcut SHORTCUT_NAME TARGET_PATH ICON_PATH
    StrCpy $StartMenuDir "$SMPROGRAMS\${APP_START_MENU_FOLDER}"
    CreateDirectory "$StartMenuDir"

    ${If} ${FileExists} "${TARGET_PATH}"
        CreateShortCut "$StartMenuDir\${SHORTCUT_NAME}.lnk" "${TARGET_PATH}" "" "${ICON_PATH}"
    ${Else}
        DetailPrint "$(C13_WARNING_PREFIX) $(C13_SHORTCUT_TARGET_MISSING_PREFIX) ${SHORTCUT_NAME}: ${TARGET_PATH}"
    ${EndIf}
!macroend

!macro CreateDesktopShortcut SHORTCUT_NAME TARGET_PATH ICON_PATH
    ${If} ${FileExists} "${TARGET_PATH}"
        CreateShortCut "$DESKTOP\${SHORTCUT_NAME}.lnk" "${TARGET_PATH}" "" "${ICON_PATH}"
    ${Else}
        DetailPrint "$(C13_WARNING_PREFIX) $(C13_DESKTOP_SHORTCUT_TARGET_MISSING_PREFIX) ${SHORTCUT_NAME}: ${TARGET_PATH}"
    ${EndIf}
!macroend

!macro CreateStartMenuWebShortcut SHORTCUT_NAME URL ICON_PATH
    StrCpy $StartMenuDir "$SMPROGRAMS\${APP_START_MENU_FOLDER}"
    CreateDirectory "$StartMenuDir"
    WriteINIStr "$StartMenuDir\${SHORTCUT_NAME}.url" "InternetShortcut" "URL" "${URL}"
    ${If} ${FileExists} "${ICON_PATH}"
        WriteINIStr "$StartMenuDir\${SHORTCUT_NAME}.url" "InternetShortcut" "IconFile" "${ICON_PATH}"
        WriteINIStr "$StartMenuDir\${SHORTCUT_NAME}.url" "InternetShortcut" "IconIndex" "0"
    ${EndIf}
!macroend

!macro CreateDesktopWebShortcut SHORTCUT_NAME URL ICON_PATH
    WriteINIStr "$DESKTOP\${SHORTCUT_NAME}.url" "InternetShortcut" "URL" "${URL}"
    ${If} ${FileExists} "${ICON_PATH}"
        WriteINIStr "$DESKTOP\${SHORTCUT_NAME}.url" "InternetShortcut" "IconFile" "${ICON_PATH}"
        WriteINIStr "$DESKTOP\${SHORTCUT_NAME}.url" "InternetShortcut" "IconIndex" "0"
    ${EndIf}
!macroend

!macro CreateXamppShortcut SHORTCUT_NAME
    ${If} ${FileExists} "$INSTDIR\${XAMPP_CONTROL_EXE_REL}"
        Call CreateXamppLauncherScript
        !insertmacro CreateToolShortcut "${SHORTCUT_NAME}" "$INSTDIR\${BIN_DIR_NAME}\codex13-xampp-control.cmd" "$INSTDIR\${XAMPP_CONTROL_EXE_REL}"
    ${Else}
        DetailPrint "$(C13_WARNING_PREFIX) $(C13_SHORTCUT_TARGET_MISSING_PREFIX) ${SHORTCUT_NAME}: $INSTDIR\${XAMPP_CONTROL_EXE_REL}"
    ${EndIf}
!macroend

!macro CreateXamppDesktopShortcut SHORTCUT_NAME
    ${If} ${FileExists} "$INSTDIR\${XAMPP_CONTROL_EXE_REL}"
        Call CreateXamppLauncherScript
        !insertmacro CreateDesktopShortcut "${SHORTCUT_NAME}" "$INSTDIR\${BIN_DIR_NAME}\codex13-xampp-control.cmd" "$INSTDIR\${XAMPP_CONTROL_EXE_REL}"
    ${Else}
        DetailPrint "$(C13_WARNING_PREFIX) $(C13_DESKTOP_SHORTCUT_TARGET_MISSING_PREFIX) ${SHORTCUT_NAME}: $INSTDIR\${XAMPP_CONTROL_EXE_REL}"
    ${EndIf}
!macroend

!macro InstallZipTool DISPLAY_NAME URL ARCHIVE_NAME EXPECTED_SHA256 DESTINATION_DIR TARGET_EXE SHORTCUT_NAME DONE_LABEL
    !insertmacro PreparePackage "${DISPLAY_NAME}" "${URL}" "${ARCHIVE_NAME}" "${EXPECTED_SHA256}" "${DONE_LABEL}"

    DetailPrint "$(C13_EXTRACTING_PREFIX) ${DISPLAY_NAME}..."
    StrCpy $9 "$INSTDIR\${DESTINATION_DIR}"
    ${If} "${DESTINATION_DIR}" == ""
        StrCpy $9 "$INSTDIR"
    ${EndIf}
    CreateDirectory "$9"
    SendMessage $mui.InstFilesPage.Text ${WM_SETTEXT} 0 "STR:$(C13_PROGRESS_EXTRACT_PREFIX)${DISPLAY_NAME}"

    nasterarchive::extract \
        /NSISDL \
        /7ZIP "$SevenZipPath" \
        /CAPTION "$(C13_EXTRACTING_PREFIX) ${DISPLAY_NAME}" \
        /TEXT "$(C13_EXTRACTING_PREFIX) ${DISPLAY_NAME}$(C13_EXTRACT_WAIT_SUFFIX)" \
        /CANCELTEXT "$(C13_CANCEL)" \
        /QUESTION "$(C13_EXTRACT_ABORT_QUESTION)" \
        "$CacheDir\${ARCHIVE_NAME}" \
        "$9" \
        /END
    Pop $0

    ${If} $0 == "OK"
        DetailPrint "${DISPLAY_NAME} $(C13_EXTRACTED_OK_SUFFIX)"
        SendMessage $mui.InstFilesPage.Text ${WM_SETTEXT} 0 "STR:${DISPLAY_NAME} $(C13_EXTRACTED_OK_SUFFIX)"
        !insertmacro LogLine "OK" "${DISPLAY_NAME} extracted successfully."
        ${If} "${SHORTCUT_NAME}" != ""
            !insertmacro CreateToolShortcut "${SHORTCUT_NAME}" "$9\${TARGET_EXE}" "$9\${TARGET_EXE}"
        ${EndIf}
    ${ElseIf} $0 == "cancel"
        StrCpy $InstallHadErrors "1"
        SendMessage $mui.InstFilesPage.Text ${WM_SETTEXT} 0 "STR:${DISPLAY_NAME} $(C13_EXTRACT_CANCELLED_SUFFIX)"
        DetailPrint "${DISPLAY_NAME} $(C13_EXTRACT_CANCELLED_SUFFIX)"
        !insertmacro LogLine "ERROR" "${DISPLAY_NAME} extraction was cancelled."
        MessageBox MB_ICONEXCLAMATION "${DISPLAY_NAME} $(C13_EXTRACT_CANCELLED_SUFFIX)"
        Goto ${DONE_LABEL}
    ${Else}
        StrCpy $InstallHadErrors "1"
        SendMessage $mui.InstFilesPage.Text ${WM_SETTEXT} 0 "STR:$(C13_EXTRACT_FAILED_PREFIX) ${DISPLAY_NAME}."
        DetailPrint "$(C13_ERROR_PREFIX) $(C13_EXTRACT_FAILED_PREFIX) ${DISPLAY_NAME}: $0"
        !insertmacro LogLine "ERROR" "Failed to extract ${DISPLAY_NAME}: $0"
        MessageBox MB_ICONEXCLAMATION "$(C13_EXTRACT_FAILED_PREFIX) ${DISPLAY_NAME}.$\r$\n$(C13_DETAILS): $0"
        Goto ${DONE_LABEL}
    ${EndIf}
!macroend

!define MUI_PAGE_CUSTOMFUNCTION_PRE SkipPageInUnattended
!insertmacro MUI_PAGE_WELCOME
!ifdef MUI_PAGE_CUSTOMFUNCTION_PRE
!undef MUI_PAGE_CUSTOMFUNCTION_PRE
!endif
Page custom TermsAndPrivacyCreate TermsAndPrivacyLeave
!define MUI_PAGE_CUSTOMFUNCTION_PRE SkipPageInUnattended
!define MUI_PAGE_CUSTOMFUNCTION_LEAVE DirectoryPageLeave
!insertmacro MUI_PAGE_DIRECTORY
!ifdef MUI_PAGE_CUSTOMFUNCTION_PRE
!undef MUI_PAGE_CUSTOMFUNCTION_PRE
!endif
!ifdef MUI_PAGE_CUSTOMFUNCTION_LEAVE
!undef MUI_PAGE_CUSTOMFUNCTION_LEAVE
!endif
Page custom ExistingInstallModeCreate ExistingInstallModeLeave
Page custom ProfilePageCreate ProfilePageLeave
Page custom PresetPageCreate PresetPageLeave
; Component selection is prepared but hidden for the first alpha.
; Page custom ComponentsPageCreate ComponentsPageLeave
Page custom ExistingComponentsOptionsCreate ExistingComponentsOptionsLeave
Page custom SummaryPageCreate SummaryPageLeave
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH

!insertmacro MUI_UNPAGE_CONFIRM
UninstPage custom un.UninstallOptionsCreate un.UninstallOptionsLeave
!insertmacro MUI_UNPAGE_INSTFILES

!insertmacro MUI_LANGUAGE "Polish"
!insertmacro MUI_LANGUAGE "English"

!include "i18n\pl.nsh"
!include "i18n\en.nsh"

Function PrepareInstallDirectories
    ${C13_DbgLog} "[PrepareInstallDirectories] enter"
    StrCpy $InstallHadErrors "0"
    ${If} $AdvancedShowDetails == "1"
        SetDetailsView show
    ${Else}
        SetDetailsView hide
    ${EndIf}
    DetailPrint "$(C13_STAGE_PREPARE)"
    SendMessage $mui.InstFilesPage.Text ${WM_SETTEXT} 0 "STR:$(C13_PROGRESS_PREPARE)"

    SetShellVarContext current
    SetOutPath "$INSTDIR"

    StrCpy $CacheDir "$INSTDIR\${PACKAGES_DIR_NAME}"
    CreateDirectory "$CacheDir"
    CreateDirectory "$INSTDIR\${TOOLS_DIR_NAME}"
    CreateDirectory "$INSTDIR\${BIN_DIR_NAME}"
    CreateDirectory "$INSTDIR\${LOGS_DIR_NAME}"
    StrCpy $OfflinePackageDir "$EXEDIR\packages"

    StrCpy $StartMenuDir "$SMPROGRAMS\$StartMenuFolder"

    InitPluginsDir
    SetOutPath "$PLUGINSDIR"

    File "..\installer-scripts\verify-package.ps1"
    StrCpy $VerifyScriptPath "$PLUGINSDIR\verify-package.ps1"

    File "..\installer-scripts\write-manifest.ps1"
    StrCpy $ManifestScriptPath "$PLUGINSDIR\write-manifest.ps1"

    File "/oname=$PLUGINSDIR\7za.exe" "..\..\vendor\tools\7zip\7za.exe"
    StrCpy $SevenZipPath "$PLUGINSDIR\7za.exe"

!if /FileExists "..\patches\xampp\delete.txt"
    File "/oname=$PLUGINSDIR\xampp-patch-delete.txt" "..\patches\xampp\delete.txt"
    StrCpy $XamppPatchDeleteListPath "$PLUGINSDIR\xampp-patch-delete.txt"
!else
    StrCpy $XamppPatchDeleteListPath ""
!endif

!if /FileExists "..\patches\xampp\commands.txt"
    File "/oname=$PLUGINSDIR\xampp-patch-commands.txt" "..\patches\xampp\commands.txt"
    StrCpy $XamppPatchCommandListPath "$PLUGINSDIR\xampp-patch-commands.txt"
!else
    StrCpy $XamppPatchCommandListPath ""
!endif

!if /FileExists "..\patches\xampp\validations.txt"
    File "/oname=$PLUGINSDIR\xampp-patch-validations.txt" "..\patches\xampp\validations.txt"
    StrCpy $XamppPatchValidationListPath "$PLUGINSDIR\xampp-patch-validations.txt"
!else
    StrCpy $XamppPatchValidationListPath ""
!endif
FunctionEnd

Function InstallRootPayload
!if /FileExists "..\payload\legal\*.*"
    DetailPrint "$(C13_COPYING_PAYLOAD)"
    SetOutPath "$INSTDIR\legal"
    File /r "..\payload\legal\*.*"
!endif
!if /FileExists "..\payload\licenses\*.*"
    DetailPrint "$(C13_COPYING_PAYLOAD)"
    SetOutPath "$INSTDIR\licenses"
    File /r "..\payload\licenses\*.*"
!endif
    CreateDirectory "$INSTDIR\${ASSETS_DIR_NAME}"
    SetOutPath "$INSTDIR\${ASSETS_DIR_NAME}"
    File "..\..\assets\nsis\codex13.ico"
!if /FileExists "..\payload\legal\*.*"
!else
!if /FileExists "..\payload\licenses\*.*"
!else
    DetailPrint "$(C13_NO_PAYLOAD)"
!endif
!endif
FunctionEnd

Function StartInstallLog
    CreateDirectory "$INSTDIR\${LOGS_DIR_NAME}"
    ${GetTime} "" "L" $1 $2 $3 $4 $5 $6 $7
    StrCpy $InstallLogPath "$INSTDIR\${LOGS_DIR_NAME}\install-$3$2$1-$5$6$7.log"

    FileOpen $0 "$InstallLogPath" w
    ${If} $0 != ""
        FileWrite $0 "Codex 13 Student Dev Kit Installer Log$\r$\n"
        FileWrite $0 "======================================$\r$\n$\r$\n"
        FileWrite $0 "Started: $3-$2-$1 $5:$6:$7 ($4)$\r$\n"
        FileWrite $0 "Version: ${BUILD_VERSION}$\r$\n$\r$\n"
        FileWrite $0 "Install root: $INSTDIR$\r$\n"
        FileWrite $0 "Profile: $ProfileId$\r$\n"
        FileWrite $0 "Preset: $PresetId$\r$\n"
        FileWrite $0 "Mode: $MaintenanceMode$\r$\n"
        ${If} $UnattendedEnabled == "1"
            FileWrite $0 "Unattended: $UnattendedFilePath$\r$\n"
            FileWrite $0 "Unattended silent: $UnattendedSilentRequested$\r$\n"
        ${EndIf}
        FileWrite $0 "Manifest: $INSTDIR\${MANIFEST_FILE_NAME}$\r$\n"
        FileWrite $0 "$\r$\nExecution log:$\r$\n"
        FileClose $0
    ${EndIf}

    !insertmacro LogLine "INFO" "Starting installation"
    !insertmacro LogLine "INFO" "Target directory: $INSTDIR"
FunctionEnd

Function CreateLauncherScripts
    CreateDirectory "$INSTDIR\${BIN_DIR_NAME}"

    FileOpen $0 "$INSTDIR\${BIN_DIR_NAME}\codex13-launcher.cmd" w
    ${If} $0 != ""
        FileWrite $0 "@echo off$\r$\n"
        FileWrite $0 "set $\"SDK_ROOT=%~dp0..$\"$\r$\n"
        FileWrite $0 "if exist $\"%SDK_ROOT%\${VSCODE_EXE_REL}$\" start $\"Codex 13$\" $\"%SDK_ROOT%\${BIN_DIR_NAME}\codex13-vscode.cmd$\"$\r$\n"
        FileWrite $0 "if not exist $\"%SDK_ROOT%\${VSCODE_EXE_REL}$\" start $\"Codex 13$\" $\"${APP_OPEN_URL}$\"$\r$\n"
        FileClose $0
    ${EndIf}

    ${If} ${FileExists} "$INSTDIR\${VSCODE_EXE_REL}"
        FileOpen $0 "$INSTDIR\${BIN_DIR_NAME}\codex13-vscode.cmd" w
        ${If} $0 != ""
            FileWrite $0 "@echo off$\r$\n"
            FileWrite $0 "setlocal$\r$\n"
            FileWrite $0 "set $\"SDK_ROOT=%~dp0..$\"$\r$\n"
            FileWrite $0 "set $\"TOOLS_DIR=%SDK_ROOT%\${TOOLS_DIR_NAME}$\"$\r$\n"
            FileWrite $0 "if exist $\"%TOOLS_DIR%\Git\cmd$\" set $\"PATH=%TOOLS_DIR%\Git\cmd;%PATH%$\"$\r$\n"
            FileWrite $0 "if exist $\"%TOOLS_DIR%\Git\bin$\" set $\"PATH=%TOOLS_DIR%\Git\bin;%PATH%$\"$\r$\n"
            FileWrite $0 "if exist $\"%TOOLS_DIR%\Node$\" set $\"PATH=%TOOLS_DIR%\Node;%PATH%$\"$\r$\n"
            FileWrite $0 "if exist $\"%TOOLS_DIR%\xampp\php$\" set $\"PATH=%TOOLS_DIR%\xampp\php;%PATH%$\"$\r$\n"
            FileWrite $0 "if exist $\"%TOOLS_DIR%\ImageMagick$\" set $\"PATH=%TOOLS_DIR%\ImageMagick;%PATH%$\"$\r$\n"
            FileWrite $0 "set $\"LANG=pl_PL.UTF-8$\"$\r$\n"
            FileWrite $0 "set $\"LC_ALL=pl_PL.UTF-8$\"$\r$\n"
            FileWrite $0 "set $\"PYTHONUTF8=1$\"$\r$\n"
            FileWrite $0 "set $\"PYTHONIOENCODING=utf-8$\"$\r$\n"
            FileWrite $0 "set $\"NODE_OPTIONS=--enable-source-maps$\"$\r$\n"
            FileWrite $0 "start $\"$\" $\"%SDK_ROOT%\${VSCODE_EXE_REL}$\" --user-data-dir $\"%SDK_ROOT%\${VSCODE_INSTALL_DIR}\data\user-data$\" --extensions-dir $\"%SDK_ROOT%\${VSCODE_INSTALL_DIR}\data\extensions$\" %*$\r$\n"
            FileClose $0
        ${EndIf}
    ${Else}
        Delete "$INSTDIR\${BIN_DIR_NAME}\codex13-vscode.cmd"
    ${EndIf}

    ${If} ${FileExists} "$INSTDIR\${XAMPP_CONTROL_EXE_REL}"
        FileOpen $0 "$INSTDIR\${BIN_DIR_NAME}\codex13-xampp-control.cmd" w
        ${If} $0 != ""
            FileWrite $0 "@echo off$\r$\n"
            FileWrite $0 "set $\"SDK_ROOT=%~dp0..$\"$\r$\n"
            FileWrite $0 "pushd $\"%SDK_ROOT%\${XAMPP_INSTALL_DIR}$\"$\r$\n"
            FileWrite $0 "start $\"$\" $\"%SDK_ROOT%\${XAMPP_CONTROL_EXE_REL}$\" %*$\r$\n"
            FileWrite $0 "popd$\r$\n"
            FileClose $0
        ${EndIf}
    ${Else}
        Delete "$INSTDIR\${BIN_DIR_NAME}\codex13-xampp-control.cmd"
    ${EndIf}

    ${If} ${FileExists} "$INSTDIR\${GIT_BASH_EXE_REL}"
        FileOpen $0 "$INSTDIR\${BIN_DIR_NAME}\codex13-git-bash.cmd" w
        ${If} $0 != ""
            FileWrite $0 "@echo off$\r$\n"
            FileWrite $0 "set $\"SDK_ROOT=%~dp0..$\"$\r$\n"
            FileWrite $0 "start $\"$\" $\"%SDK_ROOT%\${GIT_BASH_EXE_REL}$\" %*$\r$\n"
            FileClose $0
        ${EndIf}
    ${Else}
        Delete "$INSTDIR\${BIN_DIR_NAME}\codex13-git-bash.cmd"
    ${EndIf}

    ${If} ${FileExists} "$INSTDIR\${GIT_CMD_EXE_REL}"
        FileOpen $0 "$INSTDIR\${BIN_DIR_NAME}\codex13-git-cmd.cmd" w
        ${If} $0 != ""
            FileWrite $0 "@echo off$\r$\n"
            FileWrite $0 "set $\"SDK_ROOT=%~dp0..$\"$\r$\n"
            FileWrite $0 "start $\"$\" $\"%SDK_ROOT%\${GIT_CMD_EXE_REL}$\" %*$\r$\n"
            FileClose $0
        ${EndIf}
    ${Else}
        Delete "$INSTDIR\${BIN_DIR_NAME}\codex13-git-cmd.cmd"
    ${EndIf}

    ; ${If} ${FileExists} "$INSTDIR\${OPENSSH_SSH_EXE_REL}"
    ;     FileOpen $0 "$INSTDIR\${BIN_DIR_NAME}\codex13-ssh.cmd" w
    ;     ${If} $0 != ""
    ;         FileWrite $0 "@echo off$\r$\n"
    ;         FileWrite $0 "set $\"SDK_ROOT=%~dp0..$\"$\r$\n"
    ;         FileWrite $0 "$\"%SDK_ROOT%\${OPENSSH_SSH_EXE_REL}$\" %*$\r$\n"
    ;         FileClose $0
    ;     ${EndIf}
    ; ${Else}
    ;     Delete "$INSTDIR\${BIN_DIR_NAME}\codex13-ssh.cmd"
    ; ${EndIf}
FunctionEnd

Function CreateXamppLauncherScript
    CreateDirectory "$INSTDIR\${BIN_DIR_NAME}"

    ${If} ${FileExists} "$INSTDIR\${XAMPP_CONTROL_EXE_REL}"
        FileOpen $0 "$INSTDIR\${BIN_DIR_NAME}\codex13-xampp-control.cmd" w
        ${If} $0 != ""
            FileWrite $0 "@echo off$\r$\n"
            FileWrite $0 "set $\"SDK_ROOT=%~dp0..$\"$\r$\n"
            FileWrite $0 "pushd $\"%SDK_ROOT%\${XAMPP_INSTALL_DIR}$\"$\r$\n"
            FileWrite $0 "start $\"$\" $\"%SDK_ROOT%\${XAMPP_CONTROL_EXE_REL}$\" %*$\r$\n"
            FileWrite $0 "popd$\r$\n"
            FileClose $0
        ${EndIf}
    ${Else}
        Delete "$INSTDIR\${BIN_DIR_NAME}\codex13-xampp-control.cmd"
    ${EndIf}
FunctionEnd

Function InstallVisualStudioCode
    DetailPrint "$(C13_STAGE_DOWNLOAD_VERIFY)"
    SendMessage $mui.InstFilesPage.Text ${WM_SETTEXT} 0 "STR:$(C13_PROGRESS_DOWNLOAD_PREFIX)Visual Studio Code ${VSCODE_VERSION}"
    ${If} ${FileExists} "$INSTDIR\${VSCODE_INSTALL_DIR}\*.*"
        ${If} $RemoveExistingVsCode == "1"
            ${If} $PreserveVsCodeData == "1"
                Call PreserveExistingVsCodeData
                ${If} $7 != "0"
                    StrCpy $InstallHadErrors "1"
                    Goto vscode_done
                ${EndIf}
            ${EndIf}
            vscode_remove_retry:
                DetailPrint "$(C13_DETAIL_REMOVE_PREVIOUS_VSCODE)"
                !insertmacro QuietRMDir "$INSTDIR\${VSCODE_INSTALL_DIR}"
                ${If} ${FileExists} "$INSTDIR\${VSCODE_INSTALL_DIR}\*.*"
                    DetailPrint "$(C13_ERROR_PREFIX) $(C13_DETAIL_ERR_REMOVE_VSCODE)"
                    MessageBox MB_ICONEXCLAMATION|MB_RETRYCANCEL "$(C13_REMOVE_PREVIOUS_FAILED_PREFIX) Visual Studio Code.$\r$\n$(C13_CLOSE_VSCODE_TRY)" IDRETRY vscode_remove_retry
                    StrCpy $InstallHadErrors "1"
                    Goto vscode_done
                ${EndIf}
        ${Else}
            DetailPrint "$(C13_DETAIL_VSCODE_EXISTS)"
            !insertmacro LogLine "INFO" "Keeping existing Visual Studio Code; package download and archive verification skipped."
            Call ConfigureVisualStudioCode
            Call CreateLauncherScripts
            !insertmacro CreateToolShortcut "Codex 13 Visual Studio Code" "$INSTDIR\${BIN_DIR_NAME}\codex13-vscode.cmd" "$INSTDIR\${VSCODE_EXE_REL}"
            Goto vscode_done
        ${EndIf}
    ${EndIf}

    !insertmacro InstallZipTool \
        "Visual Studio Code ${VSCODE_VERSION}" \
        "${VSCODE_URL}" \
        "vscode-${VSCODE_VERSION}.zip" \
        "${VSCODE_SHA256}" \
        "${VSCODE_INSTALL_DIR}" \
        "Code.exe" \
        "" \
        vscode_done

    ${IfNot} ${FileExists} "$INSTDIR\${VSCODE_EXE_REL}"
        StrCpy $InstallHadErrors "1"
        DetailPrint "$(C13_ERROR_PREFIX) $(C13_DETAIL_ERR_CODE_NOT_FOUND)"
        !insertmacro LogLine "ERROR" "VS Code control file not found: $INSTDIR\${VSCODE_EXE_REL}"
        MessageBox MB_ICONEXCLAMATION "$(C13_INSTALL_COMPONENT_FAILED_PREFIX) Visual Studio Code.$\r$\n$\r$\n$(C13_CONTROL_FILE_NOT_FOUND)$\r$\n$INSTDIR\${VSCODE_EXE_REL}$\r$\n$\r$\n$(C13_CHECK_LOG)$\r$\n$InstallLogPath"
        Goto vscode_done
    ${EndIf}
    Call RestorePreservedVsCodeData
    ${If} $7 != "0"
        StrCpy $InstallHadErrors "1"
        Goto vscode_done
    ${EndIf}
    Call ConfigureVisualStudioCode
    Call CreateLauncherScripts
    !insertmacro CreateToolShortcut "Codex 13 Visual Studio Code" "$INSTDIR\${BIN_DIR_NAME}\codex13-vscode.cmd" "$INSTDIR\${VSCODE_EXE_REL}"

    vscode_done:
    ${If} ${FileExists} "$CacheDir\preserved-vscode\data\*.*"
        Call RestorePreservedVsCodeData
    ${EndIf}
FunctionEnd

Function ConfigureVisualStudioCode
    ${If} $VscodePortableData == "1"
        CreateDirectory "$INSTDIR\${VSCODE_INSTALL_DIR}\data"
        CreateDirectory "$INSTDIR\${VSCODE_INSTALL_DIR}\data\user-data\User"
        CreateDirectory "$INSTDIR\${VSCODE_INSTALL_DIR}\data\extensions"
        DetailPrint "$(C13_DETAIL_VSCODE_DATA_CREATED)"
        !insertmacro LogLine "INFO" "VS Code portable data: $INSTDIR\${VSCODE_INSTALL_DIR}\data"
    ${EndIf}

    ${If} $VscodeProfile == "none"
        DetailPrint "$(C13_DETAIL_VSCODE_SETTINGS_SKIPPED)"
        !insertmacro LogLine "INFO" "VS Code settings profile: none"
        Return
    ${EndIf}

    ${If} $VscodePortableData != "1"
        Return
    ${EndIf}

    ${If} ${FileExists} "$INSTDIR\${VSCODE_INSTALL_DIR}\data\user-data\User\settings.json"
        ${GetTime} "" "L" $0 $1 $2 $3 $4 $5 $6
        CopyFiles /SILENT "$INSTDIR\${VSCODE_INSTALL_DIR}\data\user-data\User\settings.json" "$INSTDIR\${VSCODE_INSTALL_DIR}\data\user-data\User\settings.json.bak-$2$1$0-$4$5$6"
        DetailPrint "$(C13_DETAIL_VSCODE_SETTINGS_BACKUP)"
        !insertmacro LogLine "WARN" "Existing settings.json preserved; backup created. Automatic merge is reserved for a future version."
        Return
    ${EndIf}

    FileOpen $0 "$INSTDIR\${VSCODE_INSTALL_DIR}\data\user-data\User\settings.json" w
    ${If} $0 != ""
        FileWrite $0 "{$\r$\n"
        FileWrite $0 "  $\"files.encoding$\": $\"utf8$\",$\r$\n"
        FileWrite $0 "  $\"files.eol$\": $\"\\n$\",$\r$\n"
        FileWrite $0 "  $\"terminal.integrated.defaultProfile.windows$\": $\"Git Bash$\",$\r$\n"
        FileWrite $0 "  $\"git.enabled$\": true,$\r$\n"
        FileWrite $0 "  $\"git.autofetch$\": true$\r$\n"
        FileWrite $0 "}$\r$\n"
        FileClose $0
        DetailPrint "$(C13_DETAIL_VSCODE_SETTINGS_CREATED) $VscodeProfile"
        !insertmacro LogLine "INFO" "VS Code settings profile written: $VscodeProfile"
    ${EndIf}
FunctionEnd

Function PreserveExistingVsCodeData
    StrCpy $7 "0"
    ${If} ${FileExists} "$INSTDIR\${VSCODE_INSTALL_DIR}\data\*.*"
        vscode_preserve_data_retry:
            !insertmacro QuietRMDir "$CacheDir\preserved-vscode"
            CreateDirectory "$CacheDir\preserved-vscode"
            DetailPrint "$(C13_DETAIL_PRESERVE_VSCODE_DATA) $INSTDIR\${VSCODE_INSTALL_DIR}\data"
            Rename "$INSTDIR\${VSCODE_INSTALL_DIR}\data" "$CacheDir\preserved-vscode\data"
            ${If} ${FileExists} "$INSTDIR\${VSCODE_INSTALL_DIR}\data\*.*"
                DetailPrint "$(C13_ERROR_PREFIX) $(C13_DETAIL_ERR_MOVE_VSCODE_DATA)"
                MessageBox MB_ICONEXCLAMATION|MB_RETRYCANCEL "$(C13_PRESERVE_FAILED_PREFIX) VS Code data.$\r$\n$(C13_CLOSE_VSCODE_TRY)" IDRETRY vscode_preserve_data_retry
                StrCpy $7 "1"
                Return
            ${EndIf}
    ${EndIf}
FunctionEnd

Function RestorePreservedVsCodeData
    StrCpy $7 "0"

    ${If} ${FileExists} "$CacheDir\preserved-vscode\data\*.*"
        vscode_restore_data_retry:
            DetailPrint "$(C13_DETAIL_RESTORE_VSCODE_DATA)"
            !insertmacro QuietRMDir "$INSTDIR\${VSCODE_INSTALL_DIR}\data"
            CreateDirectory "$INSTDIR\${VSCODE_INSTALL_DIR}"
            Rename "$CacheDir\preserved-vscode\data" "$INSTDIR\${VSCODE_INSTALL_DIR}\data"
            ${If} ${FileExists} "$CacheDir\preserved-vscode\data\*.*"
                DetailPrint "$(C13_ERROR_PREFIX) $(C13_DETAIL_ERR_RESTORE_VSCODE_DATA)"
                MessageBox MB_ICONEXCLAMATION|MB_RETRYCANCEL "$(C13_RESTORE_FAILED_PREFIX) VS Code data.$\r$\n$(C13_PRESERVED_COPY_TEMP)$\r$\n$CacheDir\preserved-vscode\data" IDRETRY vscode_restore_data_retry
                StrCpy $7 "1"
                Return
            ${EndIf}
    ${EndIf}
FunctionEnd

Function InstallGit
    DetailPrint "$(C13_STAGE_DOWNLOAD_VERIFY)"
    SendMessage $mui.InstFilesPage.Text ${WM_SETTEXT} 0 "STR:$(C13_PROGRESS_DOWNLOAD_PREFIX)Git for Windows ${GIT_VERSION}"
    ${If} ${FileExists} "$INSTDIR\${GIT_INSTALL_DIR}\git-bash.exe"
        DetailPrint "$(C13_DETAIL_GIT_EXISTS)"
        !insertmacro LogLine "INFO" "Keeping existing Git for Windows; package download and archive verification skipped."
        Call CreateLauncherScripts
        !insertmacro CreateToolShortcut "Codex 13 Git Bash" "$INSTDIR\${BIN_DIR_NAME}\codex13-git-bash.cmd" "$INSTDIR\${GIT_BASH_EXE_REL}"
        !insertmacro CreateToolShortcut "Codex 13 Git CMD" "$INSTDIR\${BIN_DIR_NAME}\codex13-git-cmd.cmd" "$INSTDIR\${GIT_CMD_EXE_REL}"
        Goto git_done
    ${EndIf}

    !insertmacro InstallZipTool \
        "Git for Windows ${GIT_VERSION}" \
        "${GIT_URL}" \
        "PortableGit-${GIT_VERSION}-64-bit.7z.exe" \
        "${GIT_SHA256}" \
        "${GIT_INSTALL_DIR}" \
        "git-bash.exe" \
        "" \
        git_done

    ${IfNot} ${FileExists} "$INSTDIR\${GIT_BASH_EXE_REL}"
        StrCpy $InstallHadErrors "1"
        DetailPrint "$(C13_ERROR_PREFIX) $(C13_DETAIL_ERR_GIT_NOT_FOUND)"
        !insertmacro LogLine "ERROR" "Git control file not found: $INSTDIR\${GIT_BASH_EXE_REL}"
        MessageBox MB_ICONEXCLAMATION "$(C13_INSTALL_COMPONENT_FAILED_PREFIX) Git for Windows.$\r$\n$\r$\n$(C13_CONTROL_FILE_NOT_FOUND)$\r$\n$INSTDIR\${GIT_BASH_EXE_REL}$\r$\n$\r$\n$(C13_CHECK_LOG)$\r$\n$InstallLogPath"
        Goto git_done
    ${EndIf}
    Call CreateLauncherScripts
    !insertmacro CreateToolShortcut "Codex 13 Git Bash" "$INSTDIR\${BIN_DIR_NAME}\codex13-git-bash.cmd" "$INSTDIR\${GIT_BASH_EXE_REL}"
    !insertmacro CreateToolShortcut "Codex 13 Git CMD" "$INSTDIR\${BIN_DIR_NAME}\codex13-git-cmd.cmd" "$INSTDIR\${GIT_CMD_EXE_REL}"

    git_done:
FunctionEnd

; Function InstallOpenSSH
;     DetailPrint "$(C13_STAGE_DOWNLOAD_VERIFY)"
;     SendMessage $mui.InstFilesPage.Text ${WM_SETTEXT} 0 "STR:$(C13_PROGRESS_DOWNLOAD_PREFIX)OpenSSH for Windows"
;     ${If} ${FileExists} "$INSTDIR\${OPENSSH_SSH_EXE_REL}"
;         DetailPrint "$(C13_DETAIL_OPENSSH_EXISTS)"
;         !insertmacro LogLine "INFO" "Keeping existing OpenSSH for Windows; package download and archive verification skipped."
;         Call CreateLauncherScripts
;         Goto openssh_done
;     ${EndIf}

;     !insertmacro InstallZipTool \
;         "OpenSSH for Windows ${OPENSSH_VERSION}" \
;         "${OPENSSH_URL}" \
;         "OpenSSH-Win64-${OPENSSH_VERSION}.zip" \
;         "${OPENSSH_SHA256}" \
;         "${TOOLS_DIR_NAME}" \
;         "OpenSSH-Win64\ssh.exe" \
;         "" \
;         openssh_done

;     ${IfNot} ${FileExists} "$INSTDIR\${OPENSSH_SSH_EXE_REL}"
;         StrCpy $InstallHadErrors "1"
;         DetailPrint "$(C13_ERROR_PREFIX) $(C13_DETAIL_ERR_SSH_NOT_FOUND)"
;         !insertmacro LogLine "ERROR" "OpenSSH control file not found: $INSTDIR\${OPENSSH_SSH_EXE_REL}"
;         MessageBox MB_ICONEXCLAMATION "$(C13_INSTALL_COMPONENT_FAILED_PREFIX) OpenSSH for Windows.$\r$\n$\r$\n$(C13_CONTROL_FILE_NOT_FOUND)$\r$\n$INSTDIR\${OPENSSH_SSH_EXE_REL}$\r$\n$\r$\n$(C13_CHECK_LOG)$\r$\n$InstallLogPath"
;         Goto openssh_done
;     ${EndIf}
;     Call CreateLauncherScripts

;     openssh_done:
; FunctionEnd

Function PreserveExistingXamppData
    StrCpy $7 "0"
    CreateDirectory "$CacheDir\preserved-xampp"

    ${If} ${FileExists} "$8\htdocs\*.*"
        xampp_preserve_htdocs_retry:
            DetailPrint "$(C13_DETAIL_PRESERVE_XAMPP_HTDOCS) $8\htdocs"
            !insertmacro QuietRMDir "$CacheDir\preserved-xampp\htdocs"
            Rename "$8\htdocs" "$CacheDir\preserved-xampp\htdocs"
            ${If} ${FileExists} "$8\htdocs\*.*"
                DetailPrint "$(C13_ERROR_PREFIX) $(C13_DETAIL_ERR_MOVE_HTDOCS)"
                MessageBox MB_ICONEXCLAMATION|MB_RETRYCANCEL "$(C13_PRESERVE_FAILED_PREFIX) htdocs.$\r$\n$(C13_CLOSE_XAMPP_TRY)" IDRETRY xampp_preserve_htdocs_retry
                StrCpy $7 "1"
                Return
            ${EndIf}
    ${EndIf}

    ${If} ${FileExists} "$8\mysql\data\*.*"
        xampp_preserve_mysql_retry:
            DetailPrint "$(C13_DETAIL_PRESERVE_XAMPP_MYSQL) $8\mysql\data"
            CreateDirectory "$CacheDir\preserved-xampp\mysql"
            !insertmacro QuietRMDir "$CacheDir\preserved-xampp\mysql\data"
            Rename "$8\mysql\data" "$CacheDir\preserved-xampp\mysql\data"
            ${If} ${FileExists} "$8\mysql\data\*.*"
                DetailPrint "$(C13_ERROR_PREFIX) $(C13_DETAIL_ERR_MOVE_MYSQL)"
                MessageBox MB_ICONEXCLAMATION|MB_RETRYCANCEL "$(C13_PRESERVE_FAILED_PREFIX) mysql\data.$\r$\n$(C13_CLOSE_MYSQL_TRY)" IDRETRY xampp_preserve_mysql_retry
                StrCpy $7 "1"
                Return
            ${EndIf}
    ${EndIf}
FunctionEnd

Function RestorePreservedXamppData
    StrCpy $7 "0"

    ${If} ${FileExists} "$CacheDir\preserved-xampp\htdocs\*.*"
        xampp_restore_htdocs_retry:
            DetailPrint "$(C13_DETAIL_RESTORE_XAMPP_HTDOCS)"
            !insertmacro QuietRMDir "$INSTDIR\${XAMPP_INSTALL_DIR}\htdocs"
            CreateDirectory "$INSTDIR\${XAMPP_INSTALL_DIR}"
            Rename "$CacheDir\preserved-xampp\htdocs" "$INSTDIR\${XAMPP_INSTALL_DIR}\htdocs"
            ${If} ${FileExists} "$CacheDir\preserved-xampp\htdocs\*.*"
                DetailPrint "$(C13_ERROR_PREFIX) $(C13_DETAIL_ERR_RESTORE_HTDOCS)"
                MessageBox MB_ICONEXCLAMATION|MB_RETRYCANCEL "$(C13_RESTORE_FAILED_PREFIX) htdocs.$\r$\n$(C13_PRESERVED_COPY_TEMP)$\r$\n$CacheDir\preserved-xampp\htdocs" IDRETRY xampp_restore_htdocs_retry
                StrCpy $7 "1"
                Return
            ${EndIf}
    ${EndIf}

    ${If} ${FileExists} "$CacheDir\preserved-xampp\mysql\data\*.*"
        xampp_restore_mysql_retry:
            DetailPrint "$(C13_DETAIL_RESTORE_XAMPP_MYSQL)"
            !insertmacro QuietRMDir "$INSTDIR\${XAMPP_INSTALL_DIR}\mysql\data"
            CreateDirectory "$INSTDIR\${XAMPP_INSTALL_DIR}\mysql"
            Rename "$CacheDir\preserved-xampp\mysql\data" "$INSTDIR\${XAMPP_INSTALL_DIR}\mysql\data"
            ${If} ${FileExists} "$CacheDir\preserved-xampp\mysql\data\*.*"
                DetailPrint "$(C13_ERROR_PREFIX) $(C13_DETAIL_ERR_RESTORE_MYSQL)"
                MessageBox MB_ICONEXCLAMATION|MB_RETRYCANCEL "$(C13_RESTORE_FAILED_PREFIX) mysql\data.$\r$\n$(C13_PRESERVED_COPY_TEMP)$\r$\n$CacheDir\preserved-xampp\mysql\data" IDRETRY xampp_restore_mysql_retry
                StrCpy $7 "1"
                Return
            ${EndIf}
    ${EndIf}
FunctionEnd

Function DeleteXamppPatchListedFiles
    ${If} $XamppPatchDeleteListPath == ""
        DetailPrint "$(C13_DETAIL_NO_XAMPP_DELETE_LIST)"
        Return
    ${EndIf}

    ${IfNot} ${FileExists} "$XamppPatchDeleteListPath"
        DetailPrint "$(C13_DETAIL_NO_XAMPP_DELETE_LIST)"
        Return
    ${EndIf}

    DetailPrint "$(C13_DETAIL_REMOVE_XAMPP_PATCH_FILES)"
    FileOpen $0 "$XamppPatchDeleteListPath" r
    ${If} $0 == ""
        DetailPrint "$(C13_WARNING_PREFIX) $(C13_DETAIL_ERR_OPEN_XAMPP_DELETE_LIST)"
        Return
    ${EndIf}

    delete_next:
        FileRead $0 $1
        IfErrors delete_done

        StrCpy $2 $1 1 -1
        ${If} $2 == "$\n"
            StrCpy $1 $1 -1
        ${EndIf}

        StrCpy $2 $1 1 -1
        ${If} $2 == "$\r"
            StrCpy $1 $1 -1
        ${EndIf}

        ${If} $1 == ""
            Goto delete_next
        ${EndIf}

        StrCpy $2 $1 1
        ${If} $2 == "#"
            Goto delete_next
        ${EndIf}

        DetailPrint "$(C13_DETAIL_REMOVE_XAMPP_PATCH_FILE) $INSTDIR\${XAMPP_INSTALL_DIR}\$1"
        !insertmacro QuietDelete "$INSTDIR\${XAMPP_INSTALL_DIR}\$1"
        !insertmacro QuietRMDir "$INSTDIR\${XAMPP_INSTALL_DIR}\$1"
        Goto delete_next

    delete_done:
        FileClose $0
FunctionEnd

Function RunXamppPatchCommands
    ${If} $XamppPatchCommandListPath == ""
        DetailPrint "$(C13_DETAIL_NO_XAMPP_COMMANDS)"
        Return
    ${EndIf}

    ${IfNot} ${FileExists} "$XamppPatchCommandListPath"
        DetailPrint "$(C13_DETAIL_NO_XAMPP_COMMANDS)"
        Return
    ${EndIf}

    DetailPrint "$(C13_DETAIL_RUN_XAMPP_COMMANDS)"
    Push $OUTDIR
    SetOutPath "$INSTDIR\${XAMPP_INSTALL_DIR}"
    FileOpen $0 "$XamppPatchCommandListPath" r
    ${If} $0 == ""
        Pop $OUTDIR
        SetOutPath "$OUTDIR"
        DetailPrint "$(C13_WARNING_PREFIX) $(C13_DETAIL_ERR_OPEN_XAMPP_COMMAND_LIST)"
        Return
    ${EndIf}

    command_next:
        FileRead $0 $1
        IfErrors command_done

        StrCpy $2 $1 1 -1
        ${If} $2 == "$\n"
            StrCpy $1 $1 -1
        ${EndIf}

        StrCpy $2 $1 1 -1
        ${If} $2 == "$\r"
            StrCpy $1 $1 -1
        ${EndIf}

        ${If} $1 == ""
            Goto command_next
        ${EndIf}

        StrCpy $2 $1 1
        ${If} $2 == "#"
            Goto command_next
        ${EndIf}

        DetailPrint "$(C13_DETAIL_XAMPP_COMMAND) $1"
        !insertmacro LogLine "INFO" "XAMPP patch command: $1"
        nsExec::ExecToStack '"$SYSDIR\cmd.exe" /C $1'
        Pop $2
        Pop $3
        ${If} $2 != "0"
            StrCpy $7 "1"
            StrCpy $InstallHadErrors "1"
            DetailPrint "$(C13_ERROR_PREFIX) $(C13_DETAIL_ERR_XAMPP_PATCH_CODE) $2."
            DetailPrint "$3"
            !insertmacro LogLine "ERROR" "XAMPP patch command exited with code $2."
            MessageBox MB_ICONEXCLAMATION "$(C13_PATCH_COMMAND_FAILED)$\r$\n$(C13_COMMAND_LABEL) $1$\r$\n$(C13_CODE_LABEL) $2"
            Goto command_done
        ${EndIf}

        ${If} $3 != ""
            DetailPrint "$3"
        ${EndIf}
        Goto command_next

    command_done:
        FileClose $0
        Pop $OUTDIR
        SetOutPath "$OUTDIR"
FunctionEnd

Function RunXamppPatchValidations
    StrCpy $7 "0"

!if "${BUILD_CHANNEL}" == "nopatch"
    DetailPrint "$(C13_DETAIL_NOPATCH_SKIP_VALIDATION)"
    Return
!endif

    ${If} $XamppPatchValidationListPath == ""
        DetailPrint "$(C13_DETAIL_NO_XAMPP_VALIDATIONS)"
        Return
    ${EndIf}

    ${IfNot} ${FileExists} "$XamppPatchValidationListPath"
        DetailPrint "$(C13_DETAIL_NO_XAMPP_VALIDATIONS)"
        Return
    ${EndIf}

    DetailPrint "$(C13_DETAIL_RUN_XAMPP_VALIDATIONS)"
    Push $OUTDIR
    SetOutPath "$INSTDIR\${XAMPP_INSTALL_DIR}"
    FileOpen $0 "$XamppPatchValidationListPath" r
    ${If} $0 == ""
        Pop $OUTDIR
        SetOutPath "$OUTDIR"
        DetailPrint "$(C13_WARNING_PREFIX) $(C13_DETAIL_ERR_OPEN_XAMPP_VALIDATION_LIST)"
        Return
    ${EndIf}

    validation_next:
        FileRead $0 $1
        IfErrors validation_done

        StrCpy $2 $1 1 -1
        ${If} $2 == "$\n"
            StrCpy $1 $1 -1
        ${EndIf}

        StrCpy $2 $1 1 -1
        ${If} $2 == "$\r"
            StrCpy $1 $1 -1
        ${EndIf}

        ${If} $1 == ""
            Goto validation_next
        ${EndIf}

        StrCpy $2 $1 1
        ${If} $2 == "#"
            Goto validation_next
        ${EndIf}

        ${If} $1 == ".\apache\bin\httpd.exe -t 2>&1"
            DetailPrint "$(C13_DETAIL_VERIFY_APACHE)"
            !insertmacro LogLine "INFO" "Verifying Apache configuration"
        ${Else}
            DetailPrint "$(C13_DETAIL_VERIFY_XAMPP)"
            !insertmacro LogLine "INFO" "Verifying XAMPP configuration"
        ${EndIf}
        nsExec::ExecToStack '"$SYSDIR\cmd.exe" /C $1'
        Pop $2
        Pop $3
        ${If} $2 != "0"
            StrCpy $7 "1"
            StrCpy $InstallHadErrors "1"
            DetailPrint "$(C13_ERROR_PREFIX) $(C13_DETAIL_ERR_XAMPP_VALIDATION_CODE) $2."
            DetailPrint "$3"
            !insertmacro LogLine "ERROR" "XAMPP validation exited with code $2."
            MessageBox MB_ICONEXCLAMATION "$(C13_VALIDATION_FAILED)$\r$\n$(C13_COMMAND_LABEL) $1$\r$\n$(C13_CODE_LABEL) $2"
            Goto validation_done
        ${EndIf}

        ${If} $3 != ""
            DetailPrint "$3"
        ${EndIf}

        Goto validation_next

    validation_done:
        FileClose $0
        Pop $OUTDIR
        SetOutPath "$OUTDIR"
FunctionEnd

Function ApplyXamppPatches
    StrCpy $7 "0"

!if "${BUILD_CHANNEL}" == "nopatch"
    DetailPrint "$(C13_DETAIL_NOPATCH_SKIP_PATCHING)"
    Return
!endif

    Call DeleteXamppPatchListedFiles
!if /FileExists "..\patches\xampp\root\*.*"
    DetailPrint "$(C13_DETAIL_APPLY_XAMPP_PATCHES)"
    SetOutPath "$INSTDIR\${XAMPP_INSTALL_DIR}"
    File /r "..\patches\xampp\root\*.*"
!else
    DetailPrint "$(C13_DETAIL_NO_XAMPP_PATCHES)"
!endif
    Call RunXamppPatchCommands
FunctionEnd

Function ConfigureXampp
    StrCpy $7 "0"
    DetailPrint "$(C13_DETAIL_CONFIGURE_XAMPP_PATHS)"
    SendMessage $mui.InstFilesPage.Text ${WM_SETTEXT} 0 "STR:$(C13_PROGRESS_CONFIGURE_XAMPP)"

    ${If} ${FileExists} "$INSTDIR\${XAMPP_INSTALL_DIR}\setup_xampp.bat"
        Push $OUTDIR
        SetOutPath "$INSTDIR\${XAMPP_INSTALL_DIR}"
        nsExec::ExecToStack '"$SYSDIR\cmd.exe" /C setup_xampp.bat'
        Pop $0
        Pop $1
        Pop $OUTDIR
        SetOutPath "$OUTDIR"

        ${If} $0 != "0"
            StrCpy $7 "1"
            StrCpy $InstallHadErrors "1"
            DetailPrint "$(C13_ERROR_PREFIX) $(C13_DETAIL_ERR_SETUP_XAMPP_CODE) $0."
            DetailPrint "$1"
            !insertmacro LogLine "ERROR" "setup_xampp.bat exited with code $0."
            MessageBox MB_ICONEXCLAMATION "$(C13_XAMPP_CONFIG_FAILED)$\r$\n$(C13_DETAILS): $0"
            Return
        ${EndIf}

        DetailPrint "$(C13_DETAIL_XAMPP_PATHS_CONFIGURED)"
        !insertmacro LogLine "OK" "XAMPP paths configured."
    ${Else}
        StrCpy $7 "1"
        StrCpy $InstallHadErrors "1"
        DetailPrint "$(C13_ERROR_PREFIX) $(C13_DETAIL_ERR_SETUP_XAMPP_NOT_FOUND)"
        !insertmacro LogLine "ERROR" "setup_xampp.bat not found."
        MessageBox MB_ICONEXCLAMATION "$(C13_DETAIL_ERR_SETUP_XAMPP_NOT_FOUND)$\r$\n$INSTDIR\${XAMPP_INSTALL_DIR}\setup_xampp.bat"
    ${EndIf}
FunctionEnd

Function InstallXampp
    ${C13_DbgLog} "[InstallXampp] enter"
    DetailPrint "$(C13_STAGE_DOWNLOAD_VERIFY)"
    SendMessage $mui.InstFilesPage.Text ${WM_SETTEXT} 0 "STR:$(C13_PROGRESS_DOWNLOAD_PREFIX)XAMPP"
    !insertmacro QuietRMDir "$CacheDir\preserved-xampp"

    ${If} ${FileExists} "$INSTDIR\${XAMPP_INSTALL_DIR}\*.*"
        ${If} $RemoveExistingXampp == "1"
            ${If} $PreserveXamppData == "1"
                StrCpy $8 "$INSTDIR\${XAMPP_INSTALL_DIR}"
                Call PreserveExistingXamppData
                ${If} $7 != "0"
                    StrCpy $InstallHadErrors "1"
                    Goto xampp_done
                ${EndIf}
            ${EndIf}

            xampp_remove_retry:
                DetailPrint "$(C13_DETAIL_REMOVE_PREVIOUS_XAMPP) $INSTDIR\${XAMPP_INSTALL_DIR}"
                !insertmacro QuietRMDir "$INSTDIR\${XAMPP_INSTALL_DIR}"
                ${If} ${FileExists} "$INSTDIR\${XAMPP_INSTALL_DIR}\*.*"
                    DetailPrint "$(C13_ERROR_PREFIX) $(C13_DETAIL_ERR_REMOVE_XAMPP)"
                    MessageBox MB_ICONEXCLAMATION|MB_RETRYCANCEL "$(C13_REMOVE_PREVIOUS_FAILED_PREFIX) XAMPP.$\r$\n$(C13_CLOSE_XAMPP_PANEL_TRY)" IDRETRY xampp_remove_retry
                    StrCpy $InstallHadErrors "1"
                    Goto xampp_done
                ${EndIf}
        ${Else}
            DetailPrint "$(C13_DETAIL_XAMPP_EXISTS)"
            !insertmacro LogLine "INFO" "Keeping existing XAMPP; package download and archive verification skipped."
            ${If} $MaintenanceMode == "repair"
                Call ApplyXamppPatches
                ${If} $7 != "0"
                    Goto xampp_done
                ${EndIf}
                Call ConfigureXampp
                ${If} $7 != "0"
                    Goto xampp_done
                ${EndIf}
                Call RunXamppPatchValidations
                ${If} $7 != "0"
                    Goto xampp_done
                ${EndIf}
            ${EndIf}
            Call CreateLauncherScripts
            !insertmacro CreateXamppShortcut "Codex 13 XAMPP Control Panel"
            !insertmacro CreateStartMenuWebShortcut "Codex 13 phpMyAdmin" "http://localhost/phpmyadmin/" "$INSTDIR\${PHPMYADMIN_ICON_REL}"
            Goto xampp_done
        ${EndIf}
    ${EndIf}

    !insertmacro PreparePackage "XAMPP" "${XAMPP_URL}" "xampp-8.2.12.zip" "${XAMPP_SHA256}" xampp_done

    DetailPrint "$(C13_EXTRACTING_PREFIX) XAMPP..."
    CreateDirectory "$INSTDIR\${TOOLS_DIR_NAME}"
    SendMessage $mui.InstFilesPage.Text ${WM_SETTEXT} 0 "STR:$(C13_PROGRESS_EXTRACT_PREFIX)XAMPP"

    ${If} $PreserveXamppData == "1"
        nasterarchive::extract \
            /NSISDL \
            /7ZIP "$SevenZipPath" \
            /EXCLUDE "xampp\htdocs" \
            /EXCLUDE "xampp\htdocs\*" \
            /EXCLUDE "xampp\mysql\data" \
            /EXCLUDE "xampp\mysql\data\*" \
            /CAPTION "$(C13_EXTRACTING_PREFIX) XAMPP" \
            /TEXT "$(C13_EXTRACTING_PREFIX) XAMPP$(C13_EXTRACT_WAIT_SUFFIX)" \
            /CANCELTEXT "$(C13_CANCEL)" \
            /QUESTION "$(C13_EXTRACT_ABORT_QUESTION)" \
            "$CacheDir\xampp-8.2.12.zip" \
            "$INSTDIR\${TOOLS_DIR_NAME}" \
            /END
    ${Else}
        nasterarchive::extract \
            /NSISDL \
            /7ZIP "$SevenZipPath" \
            /CAPTION "$(C13_EXTRACTING_PREFIX) XAMPP" \
            /TEXT "$(C13_EXTRACTING_PREFIX) XAMPP$(C13_EXTRACT_WAIT_SUFFIX)" \
            /CANCELTEXT "$(C13_CANCEL)" \
            /QUESTION "$(C13_EXTRACT_ABORT_QUESTION)" \
            "$CacheDir\xampp-8.2.12.zip" \
            "$INSTDIR\${TOOLS_DIR_NAME}" \
            /END
    ${EndIf}
    Pop $0

    ${If} $0 == "OK"
        DetailPrint "XAMPP $(C13_EXTRACTED_OK_SUFFIX)"
        SendMessage $mui.InstFilesPage.Text ${WM_SETTEXT} 0 "STR:XAMPP $(C13_EXTRACTED_OK_SUFFIX)"
        ${If} $PreserveXamppData == "1"
            Call RestorePreservedXamppData
            ${If} $7 != "0"
                StrCpy $InstallHadErrors "1"
                Goto xampp_done
            ${EndIf}
        ${EndIf}
        ${IfNot} ${FileExists} "$INSTDIR\${XAMPP_CONTROL_EXE_REL}"
            StrCpy $InstallHadErrors "1"
            DetailPrint "$(C13_ERROR_PREFIX) $(C13_DETAIL_ERR_XAMPP_CONTROL_NOT_FOUND)"
            !insertmacro LogLine "ERROR" "XAMPP control file not found: $INSTDIR\${XAMPP_CONTROL_EXE_REL}"
            MessageBox MB_ICONEXCLAMATION "$(C13_INSTALL_COMPONENT_FAILED_PREFIX) XAMPP.$\r$\n$\r$\n$(C13_CONTROL_FILE_NOT_FOUND)$\r$\n$INSTDIR\${XAMPP_CONTROL_EXE_REL}$\r$\n$\r$\n$(C13_CHECK_LOG)$\r$\n$InstallLogPath"
            Goto xampp_done
        ${EndIf}
        Call ApplyXamppPatches
        ${If} $7 != "0"
            Goto xampp_done
        ${EndIf}
        Call CreateLauncherScripts
        !insertmacro CreateXamppShortcut "Codex 13 XAMPP Control Panel"
        !insertmacro CreateStartMenuWebShortcut "Codex 13 phpMyAdmin" "http://localhost/phpmyadmin/" "$INSTDIR\${PHPMYADMIN_ICON_REL}"
    ${ElseIf} $0 == "cancel"
        StrCpy $InstallHadErrors "1"
        SendMessage $mui.InstFilesPage.Text ${WM_SETTEXT} 0 "STR:XAMPP $(C13_EXTRACT_CANCELLED_SUFFIX)"
        DetailPrint "XAMPP $(C13_EXTRACT_CANCELLED_SUFFIX)"
        MessageBox MB_ICONEXCLAMATION "XAMPP $(C13_EXTRACT_CANCELLED_SUFFIX)"
        Goto xampp_done
    ${Else}
        StrCpy $InstallHadErrors "1"
        SendMessage $mui.InstFilesPage.Text ${WM_SETTEXT} 0 "STR:$(C13_EXTRACT_FAILED_PREFIX) XAMPP."
        DetailPrint "$(C13_ERROR_PREFIX) $(C13_EXTRACT_FAILED_PREFIX) XAMPP: $0"
        MessageBox MB_ICONEXCLAMATION "$(C13_EXTRACT_FAILED_PREFIX) XAMPP.$\r$\n$(C13_DETAILS): $0"
        Goto xampp_done
    ${EndIf}

    Call ConfigureXampp
    ${If} $7 != "0"
        Goto xampp_done
    ${EndIf}

    Call RunXamppPatchValidations
    ${If} $7 != "0"
        Goto xampp_done
    ${EndIf}

    xampp_done:
    ${C13_DbgLog} "[InstallXampp] xampp_done, errors=$InstallHadErrors"
FunctionEnd

Section "-Prepare install directories"
    ${C13_DbgLog} "[Section] Prepare install directories start"
    Call PrepareInstallDirectories
    ${C13_DbgLog} "[Section] PrepareInstallDirectories done"
    Call InstallRootPayload
    ${C13_DbgLog} "[Section] InstallRootPayload done"
    Call StartInstallLog
    ${C13_DbgLog} "[Section] StartInstallLog done"
    Call CreateLauncherScripts
    ${C13_DbgLog} "[Section] CreateLauncherScripts done"
SectionEnd

Section "Visual Studio Code portable ${VSCODE_VERSION}" SEC_VSCODE
    ${C13_DbgLog} "[Section] VSCode start"
    Call InstallVisualStudioCode
    ${C13_DbgLog} "[Section] VSCode done, errors=$InstallHadErrors"
    ${If} $InstallHadErrors == "1"
        Abort
    ${EndIf}
SectionEnd

Section "Git for Windows portable ${GIT_VERSION}" SEC_GIT
    ${C13_DbgLog} "[Section] Git start"
    Call InstallGit
    ${C13_DbgLog} "[Section] Git done, errors=$InstallHadErrors"
    ${If} $InstallHadErrors == "1"
        Abort
    ${EndIf}
SectionEnd

; Section "OpenSSH for Windows" SEC_OPENSSH
;     ${C13_DbgLog} "[Section] OpenSSH start"
;     Call InstallOpenSSH
;     ${C13_DbgLog} "[Section] OpenSSH done, errors=$InstallHadErrors"
;     ${If} $InstallHadErrors == "1"
;         Abort
;     ${EndIf}
; SectionEnd

Section "XAMPP" SEC_XAMPP
    ${C13_DbgLog} "[Section] XAMPP start"
    Call InstallXampp
    ${C13_DbgLog} "[Section] XAMPP done, errors=$InstallHadErrors"
    ${If} $InstallHadErrors == "1"
        Abort
    ${EndIf}
SectionEnd

SectionGroup /e "$(C13_COMPONENTS_DESKTOP)" SEC_DESKTOP_SHORTCUTS
Section "Codex 13 Launcher" SEC_DESKTOP_CODEX13
    SetShellVarContext current
    !insertmacro CreateDesktopShortcut "Codex 13 Launcher" "$INSTDIR\${BIN_DIR_NAME}\codex13-launcher.cmd" "$INSTDIR\${CODEX13_ICON_REL}"
SectionEnd

Section "Visual Studio Code" SEC_DESKTOP_VSCODE
    SetShellVarContext current
    !insertmacro CreateDesktopShortcut "Codex 13 Visual Studio Code" "$INSTDIR\${BIN_DIR_NAME}\codex13-vscode.cmd" "$INSTDIR\${VSCODE_EXE_REL}"
SectionEnd

Section "Git Bash" SEC_DESKTOP_GIT_BASH
    SetShellVarContext current
    !insertmacro CreateDesktopShortcut "Codex 13 Git Bash" "$INSTDIR\${BIN_DIR_NAME}\codex13-git-bash.cmd" "$INSTDIR\${GIT_BASH_EXE_REL}"
SectionEnd

Section "Git CMD" SEC_DESKTOP_GIT_CMD
    SetShellVarContext current
    !insertmacro CreateDesktopShortcut "Codex 13 Git CMD" "$INSTDIR\${BIN_DIR_NAME}\codex13-git-cmd.cmd" "$INSTDIR\${GIT_CMD_EXE_REL}"
SectionEnd

Section "XAMPP Control Panel" SEC_DESKTOP_XAMPP
    SetShellVarContext current
    !insertmacro CreateXamppDesktopShortcut "Codex 13 XAMPP Control Panel"
SectionEnd

Section "phpMyAdmin" SEC_DESKTOP_PHPMYADMIN
    SetShellVarContext current
    !insertmacro CreateDesktopWebShortcut "Codex 13 phpMyAdmin" "http://localhost/phpmyadmin/" "$INSTDIR\${PHPMYADMIN_ICON_REL}"
SectionEnd
SectionGroupEnd

Function TermsAndPrivacyUpdateNext
    ${NSD_GetState} $TermsCheckLicense $0
    ${If} $0 != ${BST_CHECKED}
        GetDlgItem $1 $HWNDPARENT 1
        EnableWindow $1 0
        Return
    ${EndIf}

    ${NSD_GetState} $TermsCheckExternal $0
    ${If} $0 != ${BST_CHECKED}
        GetDlgItem $1 $HWNDPARENT 1
        EnableWindow $1 0
        Return
    ${EndIf}

    ${NSD_GetState} $TermsCheckPrivacy $0
    ${If} $0 != ${BST_CHECKED}
        GetDlgItem $1 $HWNDPARENT 1
        EnableWindow $1 0
        Return
    ${EndIf}

    GetDlgItem $1 $HWNDPARENT 1
    EnableWindow $1 1
FunctionEnd

Function TermsAndPrivacyCreate
    ${If} $UnattendedEnabled == "1"
        Abort
    ${EndIf}

    System::Call 'kernel32::LoadLibrary(t "RichEd20.dll")'
    !insertmacro MUI_HEADER_TEXT "$(C13_TERMS_TITLE)" "$(C13_TERMS_SUBTITLE)"

    nsDialogs::Create 1018
    Pop $0
    ${If} $0 == error
        Abort
    ${EndIf}

    nsDialogs::CreateControl "RICHEDIT20W" \
        "${DEFAULT_STYLES}|${WS_TABSTOP}|${WS_VSCROLL}|${ES_MULTILINE}|${ES_READONLY}|${ES_AUTOVSCROLL}|${ES_NOHIDESEL}" \
        "${WS_EX_CLIENTEDGE}" \
        0u 0u 100% 90u \
        ""
    Pop $TermsRichEdit

    InitPluginsDir
    ${If} $LANGUAGE == ${LANG_ENGLISH}
        File "/oname=$PLUGINSDIR\terms.rtf" "pages\terms-en.rtf"
    ${Else}
        File "/oname=$PLUGINSDIR\terms.rtf" "pages\terms-pl.rtf"
    ${EndIf}
    StrCpy $TermsRtfPath "$PLUGINSDIR\terms.rtf"
    ${C13_DbgLog} "[TermsPage] before LoadRTF"
    ${LoadRTF} "$TermsRtfPath" $TermsRichEdit
    ${C13_DbgLog} "[TermsPage] after LoadRTF"

    ${NSD_CreateCheckbox} 0u 99u 100% 12u "$(C13_TERMS_ACCEPT_LICENSE)"
    Pop $TermsCheckLicense
    ${NSD_CreateCheckbox} 0u 113u 100% 12u "$(C13_TERMS_ACCEPT_EXTERNAL)"
    Pop $TermsCheckExternal
    ${NSD_CreateCheckbox} 0u 127u 100% 12u "$(C13_TERMS_ACCEPT_PRIVACY)"
    Pop $TermsCheckPrivacy

    ${NSD_OnClick} $TermsCheckLicense TermsAndPrivacyUpdateNext
    ${NSD_OnClick} $TermsCheckExternal TermsAndPrivacyUpdateNext
    ${NSD_OnClick} $TermsCheckPrivacy TermsAndPrivacyUpdateNext
    Call TermsAndPrivacyUpdateNext

    nsDialogs::Show
FunctionEnd

Function TermsAndPrivacyLeave
    Call TermsAndPrivacyUpdateNext
    ${NSD_GetState} $TermsCheckLicense $0
    ${If} $0 != ${BST_CHECKED}
        Abort
    ${EndIf}
    ${NSD_GetState} $TermsCheckExternal $0
    ${If} $0 != ${BST_CHECKED}
        Abort
    ${EndIf}
    ${NSD_GetState} $TermsCheckPrivacy $0
    ${If} $0 != ${BST_CHECKED}
        Abort
    ${EndIf}
FunctionEnd

!macro SelectProfileDefaults PROFILE_ID PRESET_ID VSCODE_PROFILE SELECT_VSCODE SELECT_GIT SELECT_OPENSSH SELECT_XAMPP SELECT_DESKTOP
    StrCpy $ProfileId "${PROFILE_ID}"
    StrCpy $PresetId "${PRESET_ID}"
    StrCpy $VscodeProfile "${VSCODE_PROFILE}"
    !insertmacro SelectSection ${SEC_DESKTOP_CODEX13}

    ${If} "${SELECT_VSCODE}" == "1"
        !insertmacro SelectSection ${SEC_VSCODE}
        !insertmacro SelectSection ${SEC_DESKTOP_VSCODE}
    ${Else}
        !insertmacro UnselectSection ${SEC_VSCODE}
        !insertmacro UnselectSection ${SEC_DESKTOP_VSCODE}
    ${EndIf}

    ${If} "${SELECT_GIT}" == "1"
        !insertmacro SelectSection ${SEC_GIT}
        !insertmacro SelectSection ${SEC_DESKTOP_GIT_BASH}
    ${Else}
        !insertmacro UnselectSection ${SEC_GIT}
        !insertmacro UnselectSection ${SEC_DESKTOP_GIT_BASH}
    ${EndIf}

    !insertmacro UnselectSection ${SEC_DESKTOP_GIT_CMD}

    ; ${If} "${SELECT_OPENSSH}" == "1"
    ;     !insertmacro SelectSection ${SEC_OPENSSH}
    ; ${Else}
    ;     !insertmacro UnselectSection ${SEC_OPENSSH}
    ; ${EndIf}

    ${If} "${SELECT_XAMPP}" == "1"
        !insertmacro SelectSection ${SEC_XAMPP}
        !insertmacro SelectSection ${SEC_DESKTOP_XAMPP}
        !insertmacro SelectSection ${SEC_DESKTOP_PHPMYADMIN}
    ${Else}
        !insertmacro UnselectSection ${SEC_XAMPP}
        !insertmacro UnselectSection ${SEC_DESKTOP_XAMPP}
        !insertmacro UnselectSection ${SEC_DESKTOP_PHPMYADMIN}
    ${EndIf}

    ${If} "${SELECT_DESKTOP}" == "0"
        !insertmacro UnselectSection ${SEC_DESKTOP_CODEX13}
        !insertmacro UnselectSection ${SEC_DESKTOP_VSCODE}
        !insertmacro UnselectSection ${SEC_DESKTOP_GIT_BASH}
        !insertmacro UnselectSection ${SEC_DESKTOP_GIT_CMD}
        !insertmacro UnselectSection ${SEC_DESKTOP_XAMPP}
        !insertmacro UnselectSection ${SEC_DESKTOP_PHPMYADMIN}
    ${EndIf}

    Call .onSelChange
!macroend

Var PlannedItalicFont
Var ProfileWebPlannedLabel
Var ProfileFullstackPlannedLabel
Var ProfileCustomPlannedLabel
Var BoldFont
Var SummarySizeText

Function ProfilePageCreate
    ${If} $UnattendedEnabled == "1"
        Abort
    ${EndIf}

    !insertmacro MUI_HEADER_TEXT "$(C13_PROFILE_TITLE)" "$(C13_PROFILE_SUBTITLE)"

    nsDialogs::Create 1018
    Pop $0
    ${If} $0 == error
        Abort
    ${EndIf}

    CreateFont $PlannedItalicFont "$(^Font)" 8 400 /ITALIC

    ${NSD_CreateLabel} 0u 0u 100% 16u "$(C13_PROFILE_INTRO)"
    Pop $0

    ; --- Start ---
    ${NSD_CreateRadioButton} 0u 18u 70% 10u "Start"
    Pop $ProfileMinimalRadio

    ${NSD_CreateLabel} 12u 30u 96% 10u "$(C13_PROFILE_START_DESC)"
    Pop $0

    ; --- Web - planowane ---
    ${NSD_CreateRadioButton} 0u 42u 70% 10u "Web"
    Pop $ProfileWebRadio
    EnableWindow $ProfileWebRadio 0

    nsDialogs::CreateControl STATIC "${WS_CHILD}|${WS_VISIBLE}|${SS_RIGHT}" 0 70% 42u 30% 10u "$(C13_PLANNED)"
    Pop $ProfileWebPlannedLabel
    SendMessage $ProfileWebPlannedLabel ${WM_SETFONT} $PlannedItalicFont 1
    EnableWindow $ProfileWebPlannedLabel 0

    ${NSD_CreateLabel} 12u 54u 96% 10u "$(C13_PROFILE_WEB_DESC)"
    Pop $0
    EnableWindow $0 0

    ; --- Fullstack - planowane ---
    ${NSD_CreateRadioButton} 0u 66u 70% 10u "Fullstack"
    Pop $ProfileLabRadio
    EnableWindow $ProfileLabRadio 0

    nsDialogs::CreateControl STATIC "${WS_CHILD}|${WS_VISIBLE}|${SS_RIGHT}" 0 70% 66u 30% 10u "$(C13_PLANNED)"
    Pop $ProfileFullstackPlannedLabel
    SendMessage $ProfileFullstackPlannedLabel ${WM_SETFONT} $PlannedItalicFont 1
    EnableWindow $ProfileFullstackPlannedLabel 0

    ${NSD_CreateLabel} 12u 78u 96% 10u "$(C13_PROFILE_FULLSTACK_DESC)"
    Pop $0
    EnableWindow $0 0

    ; --- Classroom ---
    ${NSD_CreateRadioButton} 0u 90u 70% 10u "Classroom"
    Pop $ProfileCustomRadio

    ${NSD_CreateLabel} 12u 102u 96% 10u "$(C13_PROFILE_CLASSROOM_DESC)"
    Pop $0

    ; --- Custom - planowane ---
    ${NSD_CreateRadioButton} 0u 114u 70% 10u "Custom"
    Pop $VscodeNoneRadio
    EnableWindow $VscodeNoneRadio 0

    nsDialogs::CreateControl STATIC "${WS_CHILD}|${WS_VISIBLE}|${SS_RIGHT}" 0 70% 114u 30% 10u "$(C13_PLANNED)"
    Pop $ProfileCustomPlannedLabel
    SendMessage $ProfileCustomPlannedLabel ${WM_SETFONT} $PlannedItalicFont 1
    EnableWindow $ProfileCustomPlannedLabel 0

    ${NSD_CreateLabel} 12u 126u 96% 10u "$(C13_PROFILE_CUSTOM_DESC)"
    Pop $0
    EnableWindow $0 0

    ; Only the start and classroom profiles are available.
    ; If an unavailable profile was saved earlier, use classroom as the safe default.
    ${If} $ProfileId == "start"
        ${NSD_Check} $ProfileMinimalRadio
    ${Else}
        StrCpy $ProfileId "classroom"
        ${NSD_Check} $ProfileCustomRadio
    ${EndIf}

    nsDialogs::Show
FunctionEnd

Function ProfilePageLeave
    ${NSD_GetState} $ProfileMinimalRadio $0
    ${If} $0 == ${BST_CHECKED}
        !insertmacro SelectProfileDefaults "start" "clean-vscode" "clean-vscode" "1" "0" "0" "0" "1"
        Return
    ${EndIf}

    ${NSD_GetState} $ProfileLabRadio $0
    ${If} $0 == ${BST_CHECKED}
        !insertmacro SelectProfileDefaults "fullstack" "php-mysql" "php-mysql" "1" "1" "0" "1" "1"
        Return
    ${EndIf}

    ${NSD_GetState} $ProfileCustomRadio $0
    ${If} $0 == ${BST_CHECKED}
        !insertmacro SelectProfileDefaults "classroom" "php-mysql-classroom" "classroom-php-mysql" "1" "1" "0" "1" "1"
        Return
    ${EndIf}

    ${NSD_GetState} $VscodeNoneRadio $0
    ${If} $0 == ${BST_CHECKED}
        StrCpy $ProfileId "custom"
        StrCpy $PresetId "manual"
        StrCpy $VscodeProfile "manual"
        !insertmacro SelectSection ${SEC_VSCODE}
        !insertmacro SelectSection ${SEC_GIT}
        ; !insertmacro SelectSection ${SEC_OPENSSH}
        !insertmacro SelectSection ${SEC_XAMPP}
        !insertmacro SelectSection ${SEC_DESKTOP_CODEX13}
        !insertmacro SelectSection ${SEC_DESKTOP_VSCODE}
        !insertmacro SelectSection ${SEC_DESKTOP_GIT_BASH}
        !insertmacro SelectSection ${SEC_DESKTOP_GIT_CMD}
        !insertmacro SelectSection ${SEC_DESKTOP_XAMPP}
        Return
    ${EndIf}

    !insertmacro SelectProfileDefaults "web" "frontend-react-vite" "frontend-react-vite" "1" "1" "0" "0" "1"
FunctionEnd

Function PresetPageCreate
    ${If} $UnattendedEnabled == "1"
        Abort
    ${EndIf}

    !insertmacro MUI_HEADER_TEXT "$(C13_PRESET_TITLE)" "$(C13_PRESET_SUBTITLE)"

    nsDialogs::Create 1018
    Pop $0
    ${If} $0 == error
        Abort
    ${EndIf}

    CreateFont $PlannedItalicFont "$(^Font)" 8 400 /ITALIC
    CreateFont $BoldFont "$(^Font)" 8 700

    ${If} $ProfileId == "start"
        StrCpy $1 "Start"
        StrCpy $2 "$(C13_PROFILE_START_DESC)"
    ${ElseIf} $ProfileId == "classroom"
        StrCpy $1 "Classroom"
        StrCpy $2 "$(C13_PROFILE_CLASSROOM_DESC)"
    ${ElseIf} $ProfileId == "web"
        StrCpy $1 "Web"
        StrCpy $2 "$(C13_PROFILE_WEB_DESC)"
    ${ElseIf} $ProfileId == "fullstack"
        StrCpy $1 "Fullstack"
        StrCpy $2 "$(C13_PROFILE_FULLSTACK_DESC)"
    ${Else}
        StrCpy $1 "Custom"
        StrCpy $2 "$(C13_PROFILE_CUSTOM_DESC)"
    ${EndIf}

    ${NSD_CreateLabel} 0u 0u 60u 10u "$(C13_SELECTED_PROFILE)"
    Pop $0
    ${NSD_CreateLabel} 50u 0u 50% 10u "$1"
    Pop $0
    SendMessage $0 ${WM_SETFONT} $BoldFont 1
    ${NSD_CreateLabel} 0u 12u 100% 10u "$2"
    Pop $0

    ${If} $ProfileId == "start"
        ${NSD_CreateRadioButton} 0u 30u 70% 10u "$(C13_PRESET_CLEAN_VSCODE)"
        Pop $PresetRadio1
        ${NSD_CreateLabel} 12u 42u 96% 10u "$(C13_PRESET_CLEAN_VSCODE_DESC)"
        Pop $PresetLabel1

        ${NSD_CreateRadioButton} 0u 54u 70% 10u "Codex 13 Basic"
        Pop $PresetRadio2
        EnableWindow $PresetRadio2 0
        nsDialogs::CreateControl STATIC "${WS_CHILD}|${WS_VISIBLE}|${SS_RIGHT}" 0 70% 54u 30% 10u "$(C13_PLANNED)"
        Pop $PresetPlannedLabel2
        SendMessage $PresetPlannedLabel2 ${WM_SETFONT} $PlannedItalicFont 1
        EnableWindow $PresetPlannedLabel2 0
        ${NSD_CreateLabel} 12u 66u 96% 10u "$(C13_PRESET_BASIC_DESC)"
        Pop $PresetLabel2
        EnableWindow $PresetLabel2 0

        ${NSD_CreateRadioButton} 0u 78u 70% 10u "Markdown / Notes"
        Pop $PresetRadio3
        EnableWindow $PresetRadio3 0
        nsDialogs::CreateControl STATIC "${WS_CHILD}|${WS_VISIBLE}|${SS_RIGHT}" 0 70% 78u 30% 10u "$(C13_PLANNED)"
        Pop $PresetPlannedLabel3
        SendMessage $PresetPlannedLabel3 ${WM_SETFONT} $PlannedItalicFont 1
        EnableWindow $PresetPlannedLabel3 0
        ${NSD_CreateLabel} 12u 90u 96% 10u "$(C13_PRESET_MARKDOWN_DESC)"
        Pop $PresetLabel3
        EnableWindow $PresetLabel3 0
    ${ElseIf} $ProfileId == "web"
        ${NSD_CreateRadioButton} 0u 30u 100% 10u "Frontend React / Vite"
        Pop $PresetRadio1
        ${NSD_CreateLabel} 12u 42u 96% 10u "$(C13_PRESET_FRONTEND_DESC)"
        Pop $PresetLabel1
        ${NSD_CreateRadioButton} 0u 54u 100% 10u "Backend Node / API"
        Pop $PresetRadio2
        ${NSD_CreateLabel} 12u 66u 96% 10u "$(C13_PRESET_BACKEND_DESC)"
        Pop $PresetLabel2
        ${NSD_CreateRadioButton} 0u 78u 100% 10u "Static Site"
        Pop $PresetRadio3
        ${NSD_CreateLabel} 12u 90u 96% 10u "$(C13_PRESET_STATIC_DESC)"
        Pop $PresetLabel3
    ${ElseIf} $ProfileId == "fullstack"
        ${NSD_CreateRadioButton} 0u 30u 100% 10u "PHP + MySQL"
        Pop $PresetRadio1
        ${NSD_CreateLabel} 12u 42u 96% 10u "$(C13_PRESET_PHP_MYSQL_DESC)"
        Pop $PresetLabel1
        ${NSD_CreateRadioButton} 0u 54u 100% 10u "Node + API"
        Pop $PresetRadio2
        ${NSD_CreateLabel} 12u 66u 96% 10u "$(C13_PRESET_NODE_API_DESC)"
        Pop $PresetLabel2
        ${NSD_CreateRadioButton} 0u 78u 100% 10u "Mixed Stack"
        Pop $PresetRadio3
        ${NSD_CreateLabel} 12u 90u 96% 10u "$(C13_PRESET_MIXED_DESC)"
        Pop $PresetLabel3
    ${ElseIf} $ProfileId == "classroom"
        ${NSD_CreateRadioButton} 0u 30u 70% 10u "INF.03 - podstawy web"
        Pop $PresetRadio1
        EnableWindow $PresetRadio1 0
        nsDialogs::CreateControl STATIC "${WS_CHILD}|${WS_VISIBLE}|${SS_RIGHT}" 0 70% 30u 30% 10u "$(C13_PLANNED)"
        Pop $PresetPlannedLabel1
        SendMessage $PresetPlannedLabel1 ${WM_SETFONT} $PlannedItalicFont 1
        EnableWindow $PresetPlannedLabel1 0
        ${NSD_CreateLabel} 12u 42u 96% 10u "$(C13_PRESET_INF03_DESC)"
        Pop $PresetLabel1
        EnableWindow $PresetLabel1 0

        ${NSD_CreateRadioButton} 0u 54u 70% 10u "PHP + MySQL"
        Pop $PresetRadio2
        ${NSD_CreateLabel} 12u 66u 96% 10u "$(C13_PRESET_CLASSROOM_PHP_DESC)"
        Pop $PresetLabel2

        ${NSD_CreateRadioButton} 0u 78u 70% 10u "Node API"
        Pop $PresetRadio3
        EnableWindow $PresetRadio3 0
        nsDialogs::CreateControl STATIC "${WS_CHILD}|${WS_VISIBLE}|${SS_RIGHT}" 0 70% 78u 30% 10u "$(C13_PLANNED)"
        Pop $PresetPlannedLabel3
        SendMessage $PresetPlannedLabel3 ${WM_SETFONT} $PlannedItalicFont 1
        EnableWindow $PresetPlannedLabel3 0
        ${NSD_CreateLabel} 12u 90u 96% 10u "$(C13_PRESET_CLASSROOM_NODE_DESC)"
        Pop $PresetLabel3
        EnableWindow $PresetLabel3 0
    ${Else}
        ${NSD_CreateRadioButton} 0u 30u 100% 10u "Manual"
        Pop $PresetRadio1
        ${NSD_CreateLabel} 12u 42u 96% 10u "$(C13_PRESET_MANUAL_DESC)"
        Pop $PresetLabel1
        StrCpy $PresetRadio2 ""
        StrCpy $PresetRadio3 ""
    ${EndIf}

    ${NSD_Check} $PresetRadio1
    ${If} $PresetId == "markdown-notes"
    ${AndIf} $PresetRadio2 != ""
        ${NSD_Check} $PresetRadio2
    ${ElseIf} $PresetId == "codex13-basic"
    ${AndIf} $PresetRadio2 != ""
        ${NSD_Check} $PresetRadio2
    ${ElseIf} $PresetId == "backend-node-api"
    ${AndIf} $PresetRadio2 != ""
        ${NSD_Check} $PresetRadio2
    ${ElseIf} $PresetId == "node-api"
    ${AndIf} $PresetRadio2 != ""
        ${NSD_Check} $PresetRadio2
    ${ElseIf} $PresetId == "php-mysql-classroom"
    ${AndIf} $PresetRadio2 != ""
        ${NSD_Check} $PresetRadio2
    ${ElseIf} $PresetId == "static-site"
    ${AndIf} $PresetRadio3 != ""
        ${NSD_Check} $PresetRadio3
    ${ElseIf} $PresetId == "mixed-stack"
    ${AndIf} $PresetRadio3 != ""
        ${NSD_Check} $PresetRadio3
    ${ElseIf} $PresetId == "node-api-classroom"
    ${AndIf} $PresetRadio3 != ""
        ${NSD_Check} $PresetRadio3
    ${EndIf}

    ${If} $ProfileId == "classroom"
        ${NSD_Uncheck} $PresetRadio1
        ${NSD_Check} $PresetRadio2
        ${NSD_Uncheck} $PresetRadio3
    ${ElseIf} $ProfileId == "start"
        ${NSD_Check} $PresetRadio1
        ${NSD_Uncheck} $PresetRadio2
        ${NSD_Uncheck} $PresetRadio3
    ${EndIf}

    ${NSD_CreateLabel} 0u 122u 100% 24u "$(C13_PRESET_LAUNCHER_INFO)"
    Pop $0

    nsDialogs::Show
FunctionEnd

Function PresetPageLeave
    ${If} $ProfileId == "start"
        StrCpy $PresetId "clean-vscode"
        StrCpy $VscodeProfile "clean-vscode"
        !insertmacro SelectSection ${SEC_VSCODE}
        !insertmacro UnselectSection ${SEC_GIT}
        ; !insertmacro UnselectSection ${SEC_OPENSSH}
        !insertmacro UnselectSection ${SEC_XAMPP}
        !insertmacro SelectSection ${SEC_DESKTOP_CODEX13}
        !insertmacro SelectSection ${SEC_DESKTOP_VSCODE}
        !insertmacro UnselectSection ${SEC_DESKTOP_GIT_BASH}
        !insertmacro UnselectSection ${SEC_DESKTOP_GIT_CMD}
        !insertmacro UnselectSection ${SEC_DESKTOP_XAMPP}
        !insertmacro UnselectSection ${SEC_DESKTOP_PHPMYADMIN}
        ${If} $PresetRadio2 != ""
            ${NSD_GetState} $PresetRadio2 $0
            ${If} $0 == ${BST_CHECKED}
                MessageBox MB_ICONINFORMATION "$(C13_PRESET_PLANNED_CLEAN)"
                ${NSD_Check} $PresetRadio1
                Abort
            ${EndIf}
        ${EndIf}
        ${If} $PresetRadio3 != ""
            ${NSD_GetState} $PresetRadio3 $0
            ${If} $0 == ${BST_CHECKED}
                MessageBox MB_ICONINFORMATION "$(C13_PRESET_PLANNED_CLEAN)"
                ${NSD_Check} $PresetRadio1
                Abort
            ${EndIf}
        ${EndIf}
        Call .onSelChange
        Return
    ${EndIf}

    ${If} $ProfileId == "web"
        StrCpy $PresetId "frontend-react-vite"
        StrCpy $VscodeProfile "frontend-react-vite"
        ${NSD_GetState} $PresetRadio2 $0
        ${If} $0 == ${BST_CHECKED}
            StrCpy $PresetId "backend-node-api"
            StrCpy $VscodeProfile "backend-node-api"
        ${EndIf}
        ${NSD_GetState} $PresetRadio3 $0
        ${If} $0 == ${BST_CHECKED}
            StrCpy $PresetId "static-site"
            StrCpy $VscodeProfile "static-site"
        ${EndIf}
        Return
    ${EndIf}

    ${If} $ProfileId == "fullstack"
        StrCpy $PresetId "php-mysql"
        StrCpy $VscodeProfile "php-mysql"
        ${NSD_GetState} $PresetRadio2 $0
        ${If} $0 == ${BST_CHECKED}
            StrCpy $PresetId "node-api"
            StrCpy $VscodeProfile "node-api"
        ${EndIf}
        ${NSD_GetState} $PresetRadio3 $0
        ${If} $0 == ${BST_CHECKED}
            StrCpy $PresetId "mixed-stack"
            StrCpy $VscodeProfile "mixed-stack"
        ${EndIf}
        Return
    ${EndIf}

    ${If} $ProfileId == "classroom"
        StrCpy $PresetId "php-mysql-classroom"
        StrCpy $VscodeProfile "classroom-php-mysql"
        !insertmacro SelectSection ${SEC_VSCODE}
        !insertmacro SelectSection ${SEC_GIT}
        ; !insertmacro UnselectSection ${SEC_OPENSSH}
        !insertmacro SelectSection ${SEC_XAMPP}
        !insertmacro SelectSection ${SEC_DESKTOP_CODEX13}
        !insertmacro SelectSection ${SEC_DESKTOP_VSCODE}
        !insertmacro SelectSection ${SEC_DESKTOP_GIT_BASH}
        !insertmacro UnselectSection ${SEC_DESKTOP_GIT_CMD}
        !insertmacro SelectSection ${SEC_DESKTOP_XAMPP}
        !insertmacro SelectSection ${SEC_DESKTOP_PHPMYADMIN}
        ${NSD_GetState} $PresetRadio1 $0
        ${If} $0 == ${BST_CHECKED}
            MessageBox MB_ICONINFORMATION "$(C13_PRESET_PLANNED_PHP)"
            ${NSD_Check} $PresetRadio2
            Abort
        ${EndIf}
        ${NSD_GetState} $PresetRadio3 $0
        ${If} $0 == ${BST_CHECKED}
            MessageBox MB_ICONINFORMATION "$(C13_PRESET_PLANNED_PHP)"
            ${NSD_Check} $PresetRadio2
            Abort
        ${EndIf}
        Call .onSelChange
        Return
    ${EndIf}

    StrCpy $PresetId "manual"
    StrCpy $VscodeProfile "manual"
FunctionEnd

!macro CheckControlFromSection CONTROL SECTION_ID
    ${If} ${SectionIsSelected} ${SECTION_ID}
        ${NSD_Check} ${CONTROL}
    ${Else}
        ${NSD_Uncheck} ${CONTROL}
    ${EndIf}
!macroend

!macro SetSectionFromControl CONTROL SECTION_ID
    ${NSD_GetState} ${CONTROL} $0
    ${If} $0 == ${BST_CHECKED}
        !insertmacro SelectSection ${SECTION_ID}
    ${Else}
        !insertmacro UnselectSection ${SECTION_ID}
    ${EndIf}
!macroend

Function DirectoryPageLeave
    StrCpy $CacheDir "$INSTDIR\${PACKAGES_DIR_NAME}"

    StrCpy $0 $INSTDIR 10
    ${If} $0 == "$PROGRAMFILES"
        MessageBox MB_ICONEXCLAMATION|MB_OKCANCEL "$(C13_DIR_PROGRAM_FILES_WARNING)" IDOK +2
        Abort
    ${EndIf}

    StrCpy $0 $INSTDIR 10
    ${If} $0 == "$WINDIR"
        MessageBox MB_ICONEXCLAMATION|MB_OKCANCEL "$(C13_DIR_WINDOWS_WARNING)" IDOK +2
        Abort
    ${EndIf}

    ClearErrors
    CreateDirectory "$INSTDIR"
    ${If} ${Errors}
        MessageBox MB_ICONSTOP "$(C13_DIR_CREATE_FAILED)"
        Abort
    ${EndIf}
FunctionEnd

Function ExpandUnattendedInstallDir
    Exch $0
    ExpandEnvStrings $0 "$0"
    ${WordReplace} "$0" "{localappdata}" "$LOCALAPPDATA" "+" $0
    ${WordReplace} "$0" "{appdata}" "$APPDATA" "+" $0
    ${WordReplace} "$0" "{userprofile}" "$PROFILE" "+" $0
    ${WordReplace} "$0" "{desktop}" "$DESKTOP" "+" $0
    ${WordReplace} "$0" "{documents}" "$DOCUMENTS" "+" $0
    ${WordReplace} "$0" "{programfiles}" "$PROGRAMFILES" "+" $0
    ${WordReplace} "$0" "{temp}" "$TEMP" "+" $0
    Push $0
FunctionEnd

Function ApplyUnattendedProfilePreset
    ${If} $ProfileId == "start"
    ${AndIf} $PresetId == "clean-vscode"
        !insertmacro SelectProfileDefaults "start" "clean-vscode" "clean-vscode" "1" "0" "0" "0" "1"
    ${ElseIf} $ProfileId == "classroom"
    ${AndIf} $PresetId == "php-mysql-classroom"
        !insertmacro SelectProfileDefaults "classroom" "php-mysql-classroom" "classroom-php-mysql" "1" "1" "0" "1" "1"
    ${EndIf}
FunctionEnd

Function ApplyUnattendedDataOnlyDefaults
    ${If} ${SectionIsSelected} ${SEC_VSCODE}
    ${AndIfNot} ${FileExists} "$INSTDIR\${VSCODE_EXE_REL}"
    ${AndIf} ${FileExists} "$INSTDIR\${VSCODE_INSTALL_DIR}\data\*.*"
        StrCpy $RemoveExistingVsCode "1"
        StrCpy $PreserveVsCodeData "1"
    ${EndIf}

    ${If} ${SectionIsSelected} ${SEC_XAMPP}
    ${AndIfNot} ${FileExists} "$INSTDIR\${XAMPP_CONTROL_EXE_REL}"
        ${If} ${FileExists} "$INSTDIR\${XAMPP_INSTALL_DIR}\htdocs\*.*"
            StrCpy $RemoveExistingXampp "1"
            StrCpy $PreserveXamppData "1"
        ${ElseIf} ${FileExists} "$INSTDIR\${XAMPP_INSTALL_DIR}\mysql\data\*.*"
            StrCpy $RemoveExistingXampp "1"
            StrCpy $PreserveXamppData "1"
        ${EndIf}
    ${EndIf}
FunctionEnd

Function ReadUnattendedSilentParameter
    StrCpy $UnattendedSilentRequested "0"
    ${GetParameters} $0
    ClearErrors
    ${GetOptions} "$0" "/unattended-silent" $1
    ${IfNot} ${Errors}
        StrCpy $UnattendedSilentRequested "1"
    ${EndIf}
FunctionEnd

Function LoadUnattendedFile
    StrCpy $UnattendedEnabled "0"
    StrCpy $UnattendedFilePath "$EXEDIR\${UNATTENDED_FILE_NAME}"

    ${IfNot} ${FileExists} "$UnattendedFilePath"
        Return
    ${EndIf}

    ClearErrors
    ReadINIStr $0 "$UnattendedFilePath" "legal" "acceptLicense"
    ${If} ${Errors}
        Return
    ${EndIf}
    ${If} $0 != "true"
        Return
    ${EndIf}

    ClearErrors
    ReadINIStr $0 "$UnattendedFilePath" "legal" "acceptThirdParty"
    ${If} ${Errors}
        Return
    ${EndIf}
    ${If} $0 != "true"
        Return
    ${EndIf}

    ClearErrors
    ReadINIStr $0 "$UnattendedFilePath" "legal" "acceptPrivacy"
    ${If} ${Errors}
        Return
    ${EndIf}
    ${If} $0 != "true"
        Return
    ${EndIf}

    ClearErrors
    ReadINIStr $1 "$UnattendedFilePath" "install" "installDir"
    ${If} ${Errors}
        Return
    ${EndIf}
    ${If} $1 == ""
        Return
    ${EndIf}

    ClearErrors
    ReadINIStr $2 "$UnattendedFilePath" "install" "profile"
    ${If} ${Errors}
        Return
    ${EndIf}

    ClearErrors
    ReadINIStr $3 "$UnattendedFilePath" "install" "preset"
    ${If} ${Errors}
        Return
    ${EndIf}

    ${If} $2 == "start"
        ${If} $3 != "clean-vscode"
            Return
        ${EndIf}
    ${ElseIf} $2 == "classroom"
        ${If} $3 != "php-mysql-classroom"
            Return
        ${EndIf}
    ${Else}
        Return
    ${EndIf}

    Push $1
    Call ExpandUnattendedInstallDir
    Pop $INSTDIR
    StrCpy $ProfileId $2
    StrCpy $PresetId $3

    ReadINIStr $0 "$UnattendedFilePath" "install" "forceDownload"
    ${If} $0 == "true"
        StrCpy $AdvancedForceDownload "1"
    ${Else}
        StrCpy $AdvancedForceDownload "0"
    ${EndIf}

    ReadINIStr $0 "$UnattendedFilePath" "install" "showDetails"
    ${If} $0 == "true"
        StrCpy $AdvancedShowDetails "1"
    ${Else}
        StrCpy $AdvancedShowDetails "0"
    ${EndIf}

    Call ApplyUnattendedProfilePreset
    Call ApplyUnattendedDataOnlyDefaults
    StrCpy $MaintenanceMode "install"
    StrCpy $UnattendedEnabled "1"
    ${If} $UnattendedSilentRequested == "1"
        SetSilent silent
    ${EndIf}
FunctionEnd

!macro AddSelectedSectionSize SECTION_ID
    ${If} ${SectionIsSelected} ${SECTION_ID}
        SectionGetSize ${SECTION_ID} $0
        IntOp $EstimatedSizeKb $EstimatedSizeKb + $0
    ${EndIf}
!macroend

Function CalculateEstimatedSize
    StrCpy $EstimatedSizeKb "0"
    !insertmacro AddSelectedSectionSize ${SEC_VSCODE}
    !insertmacro AddSelectedSectionSize ${SEC_GIT}
    ; !insertmacro AddSelectedSectionSize ${SEC_OPENSSH}
    !insertmacro AddSelectedSectionSize ${SEC_XAMPP}
    !insertmacro AddSelectedSectionSize ${SEC_DESKTOP_CODEX13}
    !insertmacro AddSelectedSectionSize ${SEC_DESKTOP_VSCODE}
    !insertmacro AddSelectedSectionSize ${SEC_DESKTOP_GIT_BASH}
    !insertmacro AddSelectedSectionSize ${SEC_DESKTOP_GIT_CMD}
    !insertmacro AddSelectedSectionSize ${SEC_DESKTOP_XAMPP}
    !insertmacro AddSelectedSectionSize ${SEC_DESKTOP_PHPMYADMIN}
    IntOp $EstimatedSizeMb $EstimatedSizeKb / 1024
    ${If} $EstimatedSizeKb > 0
    ${AndIf} $EstimatedSizeMb < 1
        StrCpy $EstimatedSizeMb "1"
    ${EndIf}
FunctionEnd

Function FormatEstimatedSize
    ${If} $EstimatedSizeKb >= 1048576
        IntOp $0 $EstimatedSizeKb * 10
        IntOp $0 $0 / 1048576
        IntOp $1 $0 / 10
        IntOp $2 $0 % 10
        StrCpy $SummarySizeText "$1,$2 GB"
    ${Else}
        IntOp $0 $EstimatedSizeKb / 1024
        ${If} $EstimatedSizeKb > 0
        ${AndIf} $0 < 1
            StrCpy $0 "1"
        ${EndIf}
        StrCpy $SummarySizeText "$0 MB"
    ${EndIf}
FunctionEnd

!macro AddSummaryBoldLabel X Y W H TEXT
    ${NSD_CreateLabel} ${X} ${Y} ${W} ${H} "${TEXT}"
    Pop $0
    SendMessage $0 ${WM_SETFONT} $BoldFont 1
!macroend

!ifndef WS_VSCROLL
    !define WS_VSCROLL 0x00200000
!endif
!ifndef ES_MULTILINE
    !define ES_MULTILINE 0x0004
!endif
!ifndef ES_READONLY
    !define ES_READONLY 0x0800
!endif
!ifndef ES_AUTOVSCROLL
    !define ES_AUTOVSCROLL 0x0040
!endif
!ifndef ES_NOHIDESEL
    !define ES_NOHIDESEL 0x0100
!endif

Var SummaryRichEdit

Function C13_MeasureTextWidth
    ; input:
    ;   $0 = text
    ;   $1 = font handle
    ; output:
    ;   $2 = width in pixels

    Push $3
    Push $4
    Push $5
    Push $6
    Push $7

    StrLen $3 $0

    System::Call 'user32::GetDC(p $HWNDPARENT) p.r4'
    System::Call 'gdi32::SelectObject(p r4, p r1) p.r5'
    System::Call 'gdi32::GetTextExtentPoint32W(p r4, w r0, i r3, *i .r2, *i .r6) i.r7'
    System::Call 'gdi32::SelectObject(p r4, p r5)'
    System::Call 'user32::ReleaseDC(p $HWNDPARENT, p r4)'

    Pop $7
    Pop $6
    Pop $5
    Pop $4
    Pop $3
FunctionEnd

Function SummaryPageCreate
    ${If} $UnattendedEnabled == "1"
        Abort
    ${EndIf}

    !insertmacro MUI_HEADER_TEXT "$(C13_SUMMARY_TITLE)" "$(C13_SUMMARY_SUBTITLE)"

    nsDialogs::Create 1018
    Pop $0
    ${If} $0 == error
        Abort
    ${EndIf}

    Call CalculateEstimatedSize
    Call FormatEstimatedSize

    ${If} $ProfileId == "start"
        StrCpy $4 "Start"
    ${ElseIf} $ProfileId == "classroom"
        StrCpy $4 "Classroom"
    ${ElseIf} $ProfileId == "web"
        StrCpy $4 "Web"
    ${ElseIf} $ProfileId == "fullstack"
        StrCpy $4 "Fullstack"
    ${Else}
        StrCpy $4 "Custom"
    ${EndIf}

    ${If} $PresetId == "clean-vscode"
        StrCpy $5 "$(C13_PRESET_CLEAN_VSCODE)"
    ${ElseIf} $PresetId == "php-mysql-classroom"
        StrCpy $5 "PHP + MySQL"
    ${ElseIf} $PresetId == "codex13-basic"
        StrCpy $5 "Codex 13 Basic"
    ${ElseIf} $PresetId == "markdown-notes"
        StrCpy $5 "Markdown / Notes"
    ${ElseIf} $PresetId == "inf03-web-basics"
        StrCpy $5 "INF.03 - podstawy web"
    ${ElseIf} $PresetId == "node-api-classroom"
        StrCpy $5 "Node API"
    ${Else}
        StrCpy $5 "$PresetId"
    ${EndIf}

    ; ${If} $MaintenanceMode == "repair"
    ;     StrCpy $6 "$(C13_SUMMARY_REPAIR_ITEMS)"
    ;     StrCpy $7 "$(C13_SUMMARY_START_MENU_LABEL): $(C13_SUMMARY_AUTOMATIC)"
    ;     StrCpy $9 ""
    ;     Goto summary_draw
    ; ${EndIf}

    StrCpy $6 ""

    ${If} ${SectionIsSelected} ${SEC_VSCODE}
        StrCpy $6 "Visual Studio Code ${VSCODE_VERSION}"
    ${EndIf}

    ${If} ${SectionIsSelected} ${SEC_GIT}
        ${If} $6 != ""
            StrCpy $6 "$6\par "
        ${EndIf}
        StrCpy $6 "$6Git for Windows ${GIT_VERSION}"
    ${EndIf}

    ; ${If} ${SectionIsSelected} ${SEC_OPENSSH}
    ;     ${If} $6 != ""
    ;         StrCpy $6 "$6\par "
    ;     ${EndIf}
    ;     StrCpy $6 "$6OpenSSH"
    ; ${EndIf}

    ${If} ${SectionIsSelected} ${SEC_XAMPP}
        ${If} $6 != ""
            StrCpy $6 "$6\par "
        ${EndIf}
        StrCpy $6 "$6XAMPP"
    ${EndIf}

    ${If} $6 == ""
        StrCpy $6 "$(C13_SUMMARY_EMPTY_COMPONENTS)"
    ${EndIf}

    StrCpy $7 "$(C13_SUMMARY_START_MENU_LABEL): ${APP_START_MENU_FOLDER}"

    StrCpy $8 ""
    ${If} ${SectionIsSelected} ${SEC_DESKTOP_CODEX13}
        StrCpy $8 "Launcher"
    ${EndIf}

    ${If} ${SectionIsSelected} ${SEC_DESKTOP_VSCODE}
        ${If} $8 != ""
            StrCpy $8 "$8, "
        ${EndIf}
        StrCpy $8 "$8VS Code"
    ${EndIf}

    ${If} ${SectionIsSelected} ${SEC_DESKTOP_GIT_BASH}
        ${If} $8 != ""
            StrCpy $8 "$8, "
        ${EndIf}
        StrCpy $8 "$8Git Bash"
    ${EndIf}

    ${If} ${SectionIsSelected} ${SEC_DESKTOP_GIT_CMD}
        ${If} $8 != ""
            StrCpy $8 "$8, "
        ${EndIf}
        StrCpy $8 "$8Git CMD"
    ${EndIf}

    ${If} ${SectionIsSelected} ${SEC_DESKTOP_XAMPP}
        ${If} $8 != ""
            StrCpy $8 "$8, "
        ${EndIf}
        StrCpy $8 "$8XAMPP Control Panel"
    ${EndIf}

    ${If} ${SectionIsSelected} ${SEC_DESKTOP_PHPMYADMIN}
        ${If} $8 != ""
            StrCpy $8 "$8, "
        ${EndIf}
        StrCpy $8 "$8phpMyAdmin"
    ${EndIf}

    ${If} $8 == ""
        StrCpy $7 "$7\par $(C13_SUMMARY_DESKTOP_LABEL): $(C13_SUMMARY_NONE)"
    ${Else}
        StrCpy $7 "$7\par $(C13_SUMMARY_DESKTOP_LABEL): $8"
    ${EndIf}

    ${If} $RemoveExistingXampp == "1"
    ${AndIf} $PreserveXamppData == "0"
        StrCpy $9 "$(C13_SUMMARY_XAMPP_REMOVE_WARNING)"
    ${Else}
        StrCpy $9 ""
    ${EndIf}

; summary_draw:
    ${WordReplace} "$INSTDIR" "\" "\\" "+" $SummaryInstallDirRtf

    ; ${NSD_CreateLabel} 0u 0u 100% 12u "$(C13_SUMMARY_INTRO)"
    ; Pop $0

    ; Inline intro with a bold action word.
    Push $0
    Push $1
    Push $2
    Push $3
    Push $4
    Push $5
    Push $6
    Push $7
    Push $8
    Push $9

    ; $4 = normal font
    ; $5 = bold font
    System::Call 'gdi32::CreateFontW(i -12, i 0, i 0, i 0, i 400, i 0, i 0, i 0, i 238, i 0, i 0, i 0, i 0, w "Segoe UI") p.r4'
    System::Call 'gdi32::CreateFontW(i -12, i 0, i 0, i 0, i 700, i 0, i 0, i 0, i 238, i 0, i 0, i 0, i 0, w "Segoe UI") p.r5'

    ; $3 = current X in pixels
    StrCpy $3 0

    ; part 1
    StrCpy $0 "$(C13_SUMMARY_INTRO_BEFORE)"
    StrCpy $1 $4
    Call C13_MeasureTextWidth

    ${NSD_CreateLabel} $3 0u $2 12u "$0"
    Pop $6
    SendMessage $6 ${WM_SETFONT} $4 1

    IntOp $3 $3 + $2

    ; part 2 - bold
    StrCpy $0 "$(C13_SUMMARY_INTRO_INSTALL)"
    StrCpy $1 $5
    Call C13_MeasureTextWidth

    ${NSD_CreateLabel} $3 0u $2 12u "$0"
    Pop $6
    SendMessage $6 ${WM_SETFONT} $5 1

    IntOp $3 $3 + $2

    ; part 3
    StrCpy $0 "$(C13_SUMMARY_INTRO_AFTER)"
    StrCpy $1 $4
    Call C13_MeasureTextWidth

    ${NSD_CreateLabel} $3 0u $2 12u "$0"
    Pop $6
    SendMessage $6 ${WM_SETFONT} $4 1

    ; cleanup fonts after nsDialogs::Show is NOT ideal if labels still use them.
    ; For this page it is usually acceptable to leave them until process exit.
    ; Do not DeleteObject here before the page is closed.

    Pop $9
    Pop $8
    Pop $7
    Pop $6
    Pop $5
    Pop $4
    Pop $3
    Pop $2
    Pop $1
    Pop $0

    System::Call 'kernel32::LoadLibrary(t "RichEd20.dll")'
    nsDialogs::CreateControl "RICHEDIT20W" \
        "${DEFAULT_STYLES}|${WS_TABSTOP}|${WS_VSCROLL}|${ES_MULTILINE}|${ES_READONLY}|${ES_AUTOVSCROLL}|${ES_NOHIDESEL}" \
        "${WS_EX_CLIENTEDGE}" \
        0u 14u 100% 100u \
        ""
    Pop $SummaryRichEdit

    ${If} $MaintenanceMode == "repair"
        StrCpy $SummaryText "{\rtf1\ansi\ansicpg1250\deff0{\fonttbl{\f0 Segoe UI;}}\fs18 \b $(C13_SUMMARY_MODE_LABEL)\b0\par $(C13_SUMMARY_MODE_REPAIR)\par\par\b $(C13_SUMMARY_LOCATION_LABEL)\b0\par $SummaryInstallDirRtf\par\par\b $(C13_SUMMARY_PROFILE_PRESET_LABEL)\b0\par $4 / $5\par\par\b $(C13_SUMMARY_CHECKED_ITEMS_LABEL)\b0\par $6\par\par\b $(C13_SUMMARY_SHORTCUTS_LABEL)\b0\par $7\par\par\b $(C13_SUMMARY_ESTIMATED_SPACE_LABEL)\b0\par $SummarySizeText"
    ${Else}
        StrCpy $SummaryText "{\rtf1\ansi\ansicpg1250\deff0{\fonttbl{\f0 Segoe UI;}}\fs18 \b $(C13_SUMMARY_MODE_LABEL)\b0\par $(C13_SUMMARY_MODE_INSTALL_UPDATE)\par\par\b $(C13_SUMMARY_LOCATION_LABEL)\b0\par $SummaryInstallDirRtf\par\par\b $(C13_SUMMARY_PROFILE_PRESET_LABEL)\b0\par $4 / $5\par\par\b $(C13_SUMMARY_COMPONENTS_LABEL)\b0\par $6\par\par\b $(C13_SUMMARY_SHORTCUTS_LABEL)\b0\par $7\par\par\b $(C13_SUMMARY_ESTIMATED_SPACE_LABEL)\b0\par $SummarySizeText"
    ${EndIf}

    ${If} $9 != ""
        StrCpy $SummaryText "$SummaryText\par\par\b $(C13_SUMMARY_WARNING_LABEL)\b0\par $9"
    ${EndIf}

    StrCpy $SummaryText "$SummaryText}"

    InitPluginsDir
    StrCpy $SummaryRtfPath "$PLUGINSDIR\summary.rtf"
    FileOpen $0 "$SummaryRtfPath" w
    ${If} $0 == ""
        MessageBox MB_ICONEXCLAMATION "$(C13_SUMMARY_PREPARE_FAILED)"
        Abort
    ${EndIf}
    FileWrite $0 "$SummaryText"
    FileClose $0
    ${LoadRTF} "$SummaryRtfPath" $SummaryRichEdit

    ${NSD_CreateCheckbox} 0u 120u 48% 10u "$(C13_SUMMARY_FORCE_DOWNLOAD)"
    Pop $AdvancedForceDownloadCheckbox
    ${If} $AdvancedForceDownload == "1"
        ${NSD_Check} $AdvancedForceDownloadCheckbox
    ${EndIf}

    ${NSD_CreateCheckbox} 0u 130u 100% 10u "$(C13_SUMMARY_SHOW_DETAILS)"
    Pop $AdvancedShowDetailsCheckbox
    ${If} $AdvancedShowDetails == "1"
        ${NSD_Check} $AdvancedShowDetailsCheckbox
    ${EndIf}

    nsDialogs::Show
FunctionEnd

Function SummaryPageLeave
    ${NSD_GetState} $AdvancedForceDownloadCheckbox $0
    ${If} $0 == ${BST_CHECKED}
        StrCpy $AdvancedForceDownload "1"
    ${Else}
        StrCpy $AdvancedForceDownload "0"
    ${EndIf}

    ${NSD_GetState} $AdvancedShowDetailsCheckbox $0
    ${If} $0 == ${BST_CHECKED}
        StrCpy $AdvancedShowDetails "1"
    ${Else}
        StrCpy $AdvancedShowDetails "0"
    ${EndIf}

    ${If} $RemoveExistingXampp == "1"
    ${AndIf} $PreserveXamppData == "0"
        MessageBox MB_ICONEXCLAMATION|MB_OKCANCEL "$(C13_EXISTING_XAMPP_REMOVE_CONFIRM)" IDOK +2
        Abort
    ${EndIf}
FunctionEnd

Function ExistingInstallModeCreate
    ${If} $UnattendedEnabled == "1"
        Abort
    ${EndIf}

    ${IfNot} ${FileExists} "$INSTDIR\Uninstall.exe"
        Abort
    ${EndIf}

    StrCpy $MaintenanceMode "reinstall"
    StrCpy $MaintenanceReinstallRadio ""
    StrCpy $MaintenanceRepairRadio ""
    StrCpy $MaintenanceRemoveRadio ""

    !insertmacro MUI_HEADER_TEXT "$(C13_EXISTING_TITLE)" "$(C13_EXISTING_SUBTITLE)"

    nsDialogs::Create 1018
    Pop $0
    ${If} $0 == error
        Abort
    ${EndIf}

    ${NSD_CreateLabel} 0u 0u 100% 18u "$(C13_EXISTING_FOUND)"
    Pop $0

    ${NSD_CreateRadioButton} 0u 24u 100% 12u "$(C13_EXISTING_REINSTALL)"
    Pop $MaintenanceReinstallRadio
    ${NSD_Check} $MaintenanceReinstallRadio

    ${NSD_CreateLabel} 12u 38u 96% 18u "$(C13_EXISTING_REINSTALL_DESC)"
    Pop $0

    CreateFont $PlannedItalicFont "$(^Font)" 8 400 /ITALIC

    ${NSD_CreateRadioButton} 0u 62u 70% 12u "$(C13_EXISTING_REPAIR)"
    Pop $MaintenanceRepairRadio
    EnableWindow $MaintenanceRepairRadio 0
    nsDialogs::CreateControl STATIC "${WS_CHILD}|${WS_VISIBLE}|${SS_RIGHT}" 0 70% 62u 30% 10u "$(C13_PLANNED)"
    Pop $0
    SendMessage $0 ${WM_SETFONT} $PlannedItalicFont 1
    EnableWindow $0 0

    ${NSD_CreateLabel} 12u 76u 96% 18u "$(C13_EXISTING_REPAIR_DESC)"
    Pop $0
    EnableWindow $0 0

    ${NSD_CreateRadioButton} 0u 100u 100% 12u "$(C13_EXISTING_REMOVE)"
    Pop $MaintenanceRemoveRadio

    ${NSD_CreateLabel} 12u 114u 96% 18u "$(C13_EXISTING_REMOVE_DESC)"
    Pop $0

    nsDialogs::Show
FunctionEnd

Function ExistingInstallModeLeave
    StrCpy $MaintenanceMode "reinstall"

    ${NSD_GetState} $MaintenanceRepairRadio $0
    ${If} $0 == ${BST_CHECKED}
        StrCpy $MaintenanceMode "reinstall"
    ${EndIf}

    ${NSD_GetState} $MaintenanceRemoveRadio $0
    ${If} $0 == ${BST_CHECKED}
        StrCpy $MaintenanceMode "remove"
        ExecWait '"$INSTDIR\Uninstall.exe"'
        Quit
    ${EndIf}
FunctionEnd

Function SkipPageInUnattended
    ${If} $UnattendedEnabled == "1"
        Abort
    ${EndIf}
FunctionEnd

Function ExistingComponentsOptionsCreate
    ${If} $UnattendedEnabled == "1"
        Abort
    ${EndIf}

    StrCpy $RemoveExistingVsCode "0"
    StrCpy $RemoveExistingXampp "0"
    StrCpy $PreserveVsCodeData "1"
    StrCpy $PreserveXamppData "0"
    StrCpy $ExistingVsCodeCheckbox ""
    StrCpy $ExistingVsCodeDataOnly "0"
    StrCpy $ExistingXamppSkipRadio ""
    StrCpy $ExistingXamppPreserveRadio ""
    StrCpy $ExistingXamppRemoveRadio ""
    StrCpy $ExistingXamppDataOnly "0"

    ${IfNot} ${SectionIsSelected} ${SEC_VSCODE}
    ${AndIfNot} ${SectionIsSelected} ${SEC_XAMPP}
        Abort
    ${EndIf}

    StrCpy $0 "0"
    ${If} ${SectionIsSelected} ${SEC_VSCODE}
        ${If} ${FileExists} "$INSTDIR\${VSCODE_EXE_REL}"
            StrCpy $0 "1"
        ${ElseIf} ${FileExists} "$INSTDIR\${VSCODE_INSTALL_DIR}\data\*.*"
            StrCpy $0 "1"
        ${EndIf}
    ${EndIf}

    ${If} ${SectionIsSelected} ${SEC_XAMPP}
        ${If} ${FileExists} "$INSTDIR\${XAMPP_CONTROL_EXE_REL}"
            StrCpy $0 "1"
        ${ElseIf} ${FileExists} "$INSTDIR\${XAMPP_INSTALL_DIR}\htdocs\*.*"
            StrCpy $0 "1"
        ${ElseIf} ${FileExists} "$INSTDIR\${XAMPP_INSTALL_DIR}\mysql\data\*.*"
            StrCpy $0 "1"
        ${EndIf}
    ${EndIf}

    ${If} $0 != "1"
        Abort
    ${EndIf}

    !insertmacro MUI_HEADER_TEXT "$(C13_EXISTING_COMPONENTS_TITLE)" "$(C13_EXISTING_COMPONENTS_SUBTITLE)"

    nsDialogs::Create 1018
    Pop $0
    ${If} $0 == error
        Abort
    ${EndIf}

    ${If} $MaintenanceMode == "repair"
        ${NSD_CreateLabel} 0u 0u 100% 24u "$(C13_EXISTING_COMPONENTS_REPAIR_INFO)"
    ${Else}
        ${NSD_CreateLabel} 0u 0u 100% 24u "$(C13_EXISTING_COMPONENTS_INFO)"
    ${EndIf}
    Pop $0

    ${If} ${SectionIsSelected} ${SEC_VSCODE}
        ${If} ${FileExists} "$INSTDIR\${VSCODE_EXE_REL}"
            ${NSD_CreateCheckbox} 0u 34u 100% 24u "$(C13_EXISTING_VSCODE_REFRESH)"
            Pop $ExistingVsCodeCheckbox
            ${NSD_Uncheck} $ExistingVsCodeCheckbox
        ${ElseIf} ${FileExists} "$INSTDIR\${VSCODE_INSTALL_DIR}\data\*.*"
            StrCpy $ExistingVsCodeDataOnly "1"
            ${NSD_CreateCheckbox} 0u 34u 100% 24u "$(C13_EXISTING_VSCODE_DATA_REMOVE)"
            Pop $ExistingVsCodeCheckbox
            ${NSD_Uncheck} $ExistingVsCodeCheckbox
        ${EndIf}
    ${EndIf}

    ${If} ${SectionIsSelected} ${SEC_XAMPP}
        ${If} ${FileExists} "$INSTDIR\${XAMPP_CONTROL_EXE_REL}"
            ${NSD_CreateLabel} 0u 62u 100% 12u "XAMPP:"
            Pop $0

            ${If} $MaintenanceMode == "repair"
                ${NSD_CreateRadioButton} 0u 76u 100% 12u "$(C13_EXISTING_XAMPP_REPAIR)"
            ${Else}
                ${NSD_CreateRadioButton} 0u 76u 100% 12u "$(C13_EXISTING_XAMPP_KEEP)"
            ${EndIf}
            Pop $ExistingXamppSkipRadio
            ${NSD_Check} $ExistingXamppSkipRadio

            ${NSD_CreateRadioButton} 0u 92u 100% 24u "$(C13_EXISTING_XAMPP_REFRESH)"
            Pop $ExistingXamppPreserveRadio

            ${NSD_CreateRadioButton} 0u 120u 100% 12u "$(C13_EXISTING_XAMPP_REMOVE)"
            Pop $ExistingXamppRemoveRadio
        ${ElseIf} ${FileExists} "$INSTDIR\${XAMPP_INSTALL_DIR}\htdocs\*.*"
            StrCpy $ExistingXamppDataOnly "1"
            ${NSD_CreateLabel} 0u 62u 100% 12u "XAMPP:"
            Pop $0

            ${NSD_CreateRadioButton} 0u 76u 100% 24u "$(C13_EXISTING_XAMPP_DATA_REFRESH)"
            Pop $ExistingXamppPreserveRadio
            ${NSD_Check} $ExistingXamppPreserveRadio

            ${NSD_CreateRadioButton} 0u 104u 100% 24u "$(C13_EXISTING_XAMPP_REMOVE)"
            Pop $ExistingXamppRemoveRadio
        ${ElseIf} ${FileExists} "$INSTDIR\${XAMPP_INSTALL_DIR}\mysql\data\*.*"
            StrCpy $ExistingXamppDataOnly "1"
            ${NSD_CreateLabel} 0u 62u 100% 12u "XAMPP:"
            Pop $0

            ${NSD_CreateRadioButton} 0u 76u 100% 24u "$(C13_EXISTING_XAMPP_DATA_REFRESH)"
            Pop $ExistingXamppPreserveRadio
            ${NSD_Check} $ExistingXamppPreserveRadio

            ${NSD_CreateRadioButton} 0u 104u 100% 24u "$(C13_EXISTING_XAMPP_REMOVE)"
            Pop $ExistingXamppRemoveRadio
        ${EndIf}
    ${EndIf}

    nsDialogs::Show
FunctionEnd

Function ExistingComponentsOptionsLeave
    StrCpy $RemoveExistingVsCode "0"
    StrCpy $RemoveExistingXampp "0"
    StrCpy $PreserveVsCodeData "1"
    StrCpy $PreserveXamppData "0"

    ${If} $ExistingVsCodeCheckbox != ""
        ${NSD_GetState} $ExistingVsCodeCheckbox $0
        ${If} $ExistingVsCodeDataOnly == "1"
            StrCpy $RemoveExistingVsCode "1"
            ${If} $0 == ${BST_CHECKED}
                StrCpy $PreserveVsCodeData "0"
            ${Else}
                StrCpy $PreserveVsCodeData "1"
            ${EndIf}
        ${ElseIf} $0 == ${BST_CHECKED}
            StrCpy $RemoveExistingVsCode "1"
            StrCpy $PreserveVsCodeData "1"
        ${EndIf}
    ${EndIf}

    ${If} $ExistingXamppPreserveRadio != ""
        ${NSD_GetState} $ExistingXamppPreserveRadio $0
        ${If} $0 == ${BST_CHECKED}
            StrCpy $RemoveExistingXampp "1"
            StrCpy $PreserveXamppData "1"
        ${EndIf}
    ${EndIf}

    ${If} $ExistingXamppRemoveRadio != ""
        ${NSD_GetState} $ExistingXamppRemoveRadio $0
        ${If} $0 == ${BST_CHECKED}
            StrCpy $RemoveExistingXampp "1"
            StrCpy $PreserveXamppData "0"
        ${EndIf}
    ${EndIf}
FunctionEnd

Function .onInit
!ifdef C13_DEBUG_LOG_ENABLED
    FileOpen $0 "${C13_DBG_LOG}" w
    FileClose $0
!endif
    ${C13_DbgLog} "[.onInit] START"
    SetShellVarContext current
    StrCpy $MaintenanceMode "install"
    StrCpy $RemoveExistingVsCode "0"
    StrCpy $RemoveExistingXampp "0"
    StrCpy $PreserveVsCodeData "1"
    StrCpy $PreserveXamppData "0"
    StrCpy $ProfileId "fullstack"
    StrCpy $PresetId "php-mysql"
    StrCpy $VscodeProfile "php-mysql"
    StrCpy $VscodePortableData "1"
    StrCpy $VscodeGitPath "1"
    StrCpy $VscodeExtensions "0"
    StrCpy $AdvancedForceDownload "0"
    StrCpy $AdvancedShowDetails "0"
    StrCpy $UnattendedSilentRequested "0"
    StrCpy $StartMenuFolder "${APP_START_MENU_FOLDER}"
    !insertmacro SelectSection ${SEC_VSCODE}
    !insertmacro SelectSection ${SEC_GIT}
    ; !insertmacro UnselectSection ${SEC_OPENSSH}
    !insertmacro SelectSection ${SEC_XAMPP}
    !insertmacro SelectSection ${SEC_DESKTOP_CODEX13}
    !insertmacro SelectSection ${SEC_DESKTOP_VSCODE}
    !insertmacro SelectSection ${SEC_DESKTOP_GIT_BASH}
    !insertmacro UnselectSection ${SEC_DESKTOP_GIT_CMD}
    !insertmacro SelectSection ${SEC_DESKTOP_XAMPP}
    !insertmacro SelectSection ${SEC_DESKTOP_PHPMYADMIN}
    SectionSetSize ${SEC_VSCODE} ${VSCODE_SIZE_KB}
    SectionSetSize ${SEC_GIT} ${GIT_SIZE_KB}
    ; SectionSetSize ${SEC_OPENSSH} ${OPENSSH_SIZE_KB}
    SectionSetSize ${SEC_XAMPP} ${XAMPP_SIZE_KB}
    SectionSetSize ${SEC_DESKTOP_CODEX13} 1
    SectionSetSize ${SEC_DESKTOP_VSCODE} 1
    SectionSetSize ${SEC_DESKTOP_GIT_BASH} 1
    SectionSetSize ${SEC_DESKTOP_GIT_CMD} 1
    SectionSetSize ${SEC_DESKTOP_XAMPP} 1
    SectionSetSize ${SEC_DESKTOP_PHPMYADMIN} 1
    Call ReadUnattendedSilentParameter
    Call LoadUnattendedFile
    ${If} $UnattendedEnabled != "1"
        !insertmacro MUI_LANGDLL_DISPLAY
    ${EndIf}
    Call .onSelChange
    ${C13_DbgLog} "[.onInit] END"
FunctionEnd

!macro SyncShortcutSection TOOL_SECTION SHORTCUT_SECTION
    ${If} ${SectionIsSelected} ${TOOL_SECTION}
        !insertmacro ClearSectionFlag ${SHORTCUT_SECTION} ${SF_RO}
    ${Else}
        !insertmacro UnselectSection ${SHORTCUT_SECTION}
        !insertmacro SetSectionFlag ${SHORTCUT_SECTION} ${SF_RO}
    ${EndIf}
!macroend

Function .onSelChange
    !insertmacro SyncShortcutSection ${SEC_VSCODE} ${SEC_DESKTOP_VSCODE}
    !insertmacro SyncShortcutSection ${SEC_GIT} ${SEC_DESKTOP_GIT_BASH}
    !insertmacro SyncShortcutSection ${SEC_GIT} ${SEC_DESKTOP_GIT_CMD}
    !insertmacro SyncShortcutSection ${SEC_XAMPP} ${SEC_DESKTOP_XAMPP}
    !insertmacro SyncShortcutSection ${SEC_XAMPP} ${SEC_DESKTOP_PHPMYADMIN}
FunctionEnd

Function RegisterInstall
    SetShellVarContext current

    WriteUninstaller "$INSTDIR\Uninstall.exe"
    StrCpy $StartMenuDir "$SMPROGRAMS\${APP_START_MENU_FOLDER}"
    CreateDirectory "$StartMenuDir"
    CreateShortCut "$StartMenuDir\$(C13_SHORTCUT_UNINSTALL).lnk" "$INSTDIR\Uninstall.exe"
    CreateShortCut "$StartMenuDir\$(C13_SHORTCUT_OPEN_INSTALL_DIR).lnk" "$INSTDIR"
    ${If} ${FileExists} "$INSTDIR\${BIN_DIR_NAME}\codex13-launcher.cmd"
        CreateShortCut "$StartMenuDir\Codex 13 Launcher.lnk" "$INSTDIR\${BIN_DIR_NAME}\codex13-launcher.cmd" "" "$INSTDIR\${CODEX13_ICON_REL}"
    ${EndIf}
    ${If} ${FileExists} "$INSTDIR\${BIN_DIR_NAME}\codex13-vscode.cmd"
    ${AndIf} ${FileExists} "$INSTDIR\${VSCODE_EXE_REL}"
        CreateShortCut "$StartMenuDir\Codex 13 Visual Studio Code.lnk" "$INSTDIR\${BIN_DIR_NAME}\codex13-vscode.cmd" "" "$INSTDIR\${VSCODE_EXE_REL}"
    ${EndIf}
    ${If} ${FileExists} "$INSTDIR\${BIN_DIR_NAME}\codex13-git-bash.cmd"
    ${AndIf} ${FileExists} "$INSTDIR\${GIT_BASH_EXE_REL}"
        CreateShortCut "$StartMenuDir\Codex 13 Git Bash.lnk" "$INSTDIR\${BIN_DIR_NAME}\codex13-git-bash.cmd" "" "$INSTDIR\${GIT_BASH_EXE_REL}"
    ${EndIf}
    ${If} ${FileExists} "$INSTDIR\${BIN_DIR_NAME}\codex13-git-cmd.cmd"
    ${AndIf} ${FileExists} "$INSTDIR\${GIT_CMD_EXE_REL}"
        CreateShortCut "$StartMenuDir\Codex 13 Git CMD.lnk" "$INSTDIR\${BIN_DIR_NAME}\codex13-git-cmd.cmd" "" "$INSTDIR\${GIT_CMD_EXE_REL}"
    ${EndIf}
    ${If} ${FileExists} "$INSTDIR\${XAMPP_CONTROL_EXE_REL}"
        Call CreateXamppLauncherScript
    ${EndIf}
    ${If} ${FileExists} "$INSTDIR\${XAMPP_CONTROL_EXE_REL}"
        CreateShortCut "$StartMenuDir\Codex 13 XAMPP Control Panel.lnk" "$INSTDIR\${BIN_DIR_NAME}\codex13-xampp-control.cmd" "" "$INSTDIR\${XAMPP_CONTROL_EXE_REL}"
        !insertmacro CreateStartMenuWebShortcut "Codex 13 phpMyAdmin" "http://localhost/phpmyadmin/" "$INSTDIR\${PHPMYADMIN_ICON_REL}"
    ${EndIf}
    !insertmacro CreateStartMenuWebShortcut "$(C13_SHORTCUT_OPEN_SITE)" "${APP_OPEN_URL}" "$INSTDIR\${CODEX13_ICON_REL}"

    WriteRegStr HKCU "${APP_SETTINGS_REG_KEY}" "InstallDir" "$INSTDIR"
    WriteRegStr HKCU "${APP_SETTINGS_REG_KEY}" "CacheDir" "$CacheDir"
    WriteRegStr HKCU "${APP_SETTINGS_REG_KEY}" "ToolsDir" "$INSTDIR\${TOOLS_DIR_NAME}"
    WriteRegStr HKCU "${APP_SETTINGS_REG_KEY}" "BinDir" "$INSTDIR\${BIN_DIR_NAME}"
    WriteRegStr HKCU "${APP_SETTINGS_REG_KEY}" "LogsDir" "$INSTDIR\${LOGS_DIR_NAME}"

    WriteRegStr HKCU "${UNINSTALL_REG_KEY}" "DisplayName" "${APP_NAME}"
    WriteRegStr HKCU "${UNINSTALL_REG_KEY}" "DisplayVersion" "${BUILD_VERSION}"
    WriteRegStr HKCU "${UNINSTALL_REG_KEY}" "Publisher" "${APP_PUBLISHER}"
    WriteRegStr HKCU "${UNINSTALL_REG_KEY}" "InstallLocation" "$INSTDIR"
    WriteRegStr HKCU "${UNINSTALL_REG_KEY}" "UninstallString" '"$INSTDIR\Uninstall.exe"'
    WriteRegStr HKCU "${UNINSTALL_REG_KEY}" "QuietUninstallString" '"$INSTDIR\Uninstall.exe" /S'
    WriteRegStr HKCU "${UNINSTALL_REG_KEY}" "DisplayIcon" "$INSTDIR\Uninstall.exe"
    WriteRegStr HKCU "${UNINSTALL_REG_KEY}" "HelpLink" "${APP_WEBSITE}"
    WriteRegStr HKCU "${UNINSTALL_REG_KEY}" "URLInfoAbout" "${APP_WEBSITE}"
    WriteRegStr HKCU "${UNINSTALL_REG_KEY}" "URLUpdateInfo" "${APP_WEBSITE}"
    WriteRegStr HKCU "${UNINSTALL_REG_KEY}" "Contact" "${APP_PUBLISHER}"
    WriteRegStr HKCU "${UNINSTALL_REG_KEY}" "Comments" "${APP_DESCRIPTION_PL}"
    WriteRegStr HKCU "${UNINSTALL_REG_KEY}" "InstallSource" "$EXEDIR"
    WriteRegStr HKCU "${UNINSTALL_REG_KEY}" "Readme" "${APP_WEBSITE}"
    ${GetTime} "" "L" $0 $1 $2 $3 $4 $5 $6
    WriteRegStr HKCU "${UNINSTALL_REG_KEY}" "InstallDate" "$2$1$0"
    WriteRegDWORD HKCU "${UNINSTALL_REG_KEY}" "NoModify" 1
    WriteRegDWORD HKCU "${UNINSTALL_REG_KEY}" "NoRepair" 1
FunctionEnd

Function WriteInstallManifest
    ${If} $VscodePortableData == "1"
        StrCpy $0 "true"
    ${Else}
        StrCpy $0 "false"
    ${EndIf}
    StrCpy $3 ""
    ${If} ${SectionIsSelected} ${SEC_DESKTOP_CODEX13}
        StrCpy $3 "codex13-launcher"
    ${EndIf}
    ${If} ${SectionIsSelected} ${SEC_DESKTOP_VSCODE}
        ${If} $3 != ""
            StrCpy $3 "$3,"
        ${EndIf}
        StrCpy $3 "$3vscode"
    ${EndIf}
    ${If} ${SectionIsSelected} ${SEC_DESKTOP_GIT_BASH}
        ${If} $3 != ""
            StrCpy $3 "$3,"
        ${EndIf}
        StrCpy $3 "$3git-bash"
    ${EndIf}
    ${If} ${SectionIsSelected} ${SEC_DESKTOP_GIT_CMD}
        ${If} $3 != ""
            StrCpy $3 "$3,"
        ${EndIf}
        StrCpy $3 "$3git-cmd"
    ${EndIf}
    ${If} ${SectionIsSelected} ${SEC_DESKTOP_XAMPP}
        ${If} $3 != ""
            StrCpy $3 "$3,"
        ${EndIf}
        StrCpy $3 "$3xampp-control"
    ${EndIf}
    ${If} ${SectionIsSelected} ${SEC_DESKTOP_PHPMYADMIN}
        ${If} $3 != ""
            StrCpy $3 "$3,"
        ${EndIf}
        StrCpy $3 "$3phpmyadmin"
    ${EndIf}
    ${C13_DbgLog} "[WriteManifest] launching PowerShell"
    nsExec::ExecToStack '"$SYSDIR\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "$ManifestScriptPath" -InstallRoot "$INSTDIR" -Profile "$ProfileId" -Preset "$PresetId" -Mode "$MaintenanceMode" -LogPath "$InstallLogPath" -VsCodeProfile "$VscodeProfile" -VsCodePortableData $0 -DesktopShortcuts "$3" -ManifestFileName "${MANIFEST_FILE_NAME}"'
    Pop $1
    Pop $2
    ${C13_DbgLog} "[WriteManifest] PowerShell exit=$1"
    ${If} $2 != ""
        DetailPrint "$2"
    ${EndIf}
    ${If} $1 != "0"
        DetailPrint "$(C13_WARNING_PREFIX) $(C13_DETAIL_ERR_MANIFEST_WRITE) $1"
        !insertmacro LogLine "WARN" "Failed to write manifest. Code: $1"
        StrCpy $InstallHadErrors "1"
        Return
    ${EndIf}

    ${IfNot} ${FileExists} "$INSTDIR\${MANIFEST_FILE_NAME}"
        DetailPrint "$(C13_WARNING_PREFIX) $(C13_DETAIL_ERR_MANIFEST_WRITE) $INSTDIR\${MANIFEST_FILE_NAME}"
        !insertmacro LogLine "ERROR" "Manifest file was not created: $INSTDIR\${MANIFEST_FILE_NAME}"
        StrCpy $InstallHadErrors "1"
    ${Else}
        !insertmacro LogLine "INFO" "Manifest written: $INSTDIR\${MANIFEST_FILE_NAME}"
    ${EndIf}
FunctionEnd

Function ShowFinalInstallStatus
    ${If} $InstallHadErrors == "1"
        SetErrorLevel 1
        SetAutoClose false
        SetDetailsView show
        DetailPrint "$(C13_INSTALL_COMPLETED_ERRORS)"
        !insertmacro LogLine "ERROR" "Installation completed with errors"
        SendMessage $mui.InstFilesPage.Text ${WM_SETTEXT} 0 "STR:$(C13_INSTALL_COMPLETED_ERRORS_TEXT)"
    ${Else}
        SetErrorLevel 0
        SetAutoClose true
        DetailPrint "$(C13_INSTALL_COMPLETED_OK)"
        !insertmacro LogLine "INFO" "Installed files summary:"
        ${If} ${FileExists} "$INSTDIR\${VSCODE_EXE_REL}"
            !insertmacro LogLine "INFO" "- Visual Studio Code: $INSTDIR\${VSCODE_INSTALL_DIR}"
        ${EndIf}
        ${If} ${FileExists} "$INSTDIR\${GIT_BASH_EXE_REL}"
            !insertmacro LogLine "INFO" "- Git for Windows: $INSTDIR\${GIT_INSTALL_DIR}"
        ${EndIf}
        ; ${If} ${FileExists} "$INSTDIR\${OPENSSH_SSH_EXE_REL}"
        ;     !insertmacro LogLine "INFO" "- OpenSSH for Windows: $INSTDIR\${OPENSSH_INSTALL_DIR}"
        ; ${EndIf}
        ${If} ${FileExists} "$INSTDIR\${XAMPP_CONTROL_EXE_REL}"
            !insertmacro LogLine "INFO" "- XAMPP: $INSTDIR\${XAMPP_INSTALL_DIR}"
        ${EndIf}
        !insertmacro LogLine "INFO" "- Legal notices: $INSTDIR\legal"
        !insertmacro LogLine "INFO" "- License texts: $INSTDIR\licenses"
        !insertmacro LogLine "INFO" "- Manifest: $INSTDIR\${MANIFEST_FILE_NAME}"
        !insertmacro LogLine "SUCCESS" "Installation completed successfully"
    ${EndIf}
FunctionEnd

Function FinishRunLauncher
    ExecShell "open" "${APP_OPEN_URL}"
FunctionEnd

Function .onInstSuccess
    ${C13_DbgLog} "[.onInstSuccess]"
    SetErrorLevel 0
FunctionEnd

Function .onInstFailed
    ${C13_DbgLog} "[.onInstFailed]"
    SetErrorLevel 1
FunctionEnd

Function OnUserAbort
    SetErrorLevel 2
FunctionEnd

Section "-Registration and shortcuts"
    ${C13_DbgLog} "[Section] Registration and shortcuts start"
    Call WriteInstallManifest
    ${C13_DbgLog} "[Section] WriteInstallManifest done"
    ${If} $InstallHadErrors == "1"
        Abort
    ${EndIf}
    Call RegisterInstall
    ${C13_DbgLog} "[Section] RegisterInstall done"
SectionEnd

Section "-Final status"
    ${C13_DbgLog} "[Section] Final status start"
    Call ShowFinalInstallStatus
    ${C13_DbgLog} "[Section] ShowFinalInstallStatus done"
SectionEnd

Function un.UpdateUninstallOptions
    ${NSD_GetState} $UnRemoveInstallDirCheckbox $0
    ${If} $0 == ${BST_CHECKED}
        ${NSD_Uncheck} $UnRemoveCacheCheckbox
        EnableWindow $UnRemoveCacheCheckbox 0
        ${NSD_Uncheck} $UnRemoveLogsCheckbox
        EnableWindow $UnRemoveLogsCheckbox 0
        ${If} $UnRemoveVsCodeDataCheckbox != ""
            EnableWindow $UnRemoveVsCodeDataCheckbox 0
        ${EndIf}
        ${If} $UnRemoveXamppHtdocsCheckbox != ""
            EnableWindow $UnRemoveXamppHtdocsCheckbox 0
        ${EndIf}
        ${If} $UnRemoveXamppMysqlDataCheckbox != ""
            EnableWindow $UnRemoveXamppMysqlDataCheckbox 0
        ${EndIf}
        ; ${If} $UnRemoveOpenSshKeysCheckbox != ""
        ;     EnableWindow $UnRemoveOpenSshKeysCheckbox 0
        ; ${EndIf}
    ${Else}
        EnableWindow $UnRemoveCacheCheckbox 1
        EnableWindow $UnRemoveLogsCheckbox 1
        ${If} $UnRemoveVsCodeDataCheckbox != ""
            EnableWindow $UnRemoveVsCodeDataCheckbox 1
        ${EndIf}
        ${If} $UnRemoveXamppHtdocsCheckbox != ""
            EnableWindow $UnRemoveXamppHtdocsCheckbox 1
        ${EndIf}
        ${If} $UnRemoveXamppMysqlDataCheckbox != ""
            EnableWindow $UnRemoveXamppMysqlDataCheckbox 1
        ${EndIf}
        ; ${If} $UnRemoveOpenSshKeysCheckbox != ""
        ;     EnableWindow $UnRemoveOpenSshKeysCheckbox 1
        ; ${EndIf}
    ${EndIf}
FunctionEnd

Var UnOptionsY
Var UnOptionsYUnit

!macro C13_AdvanceY AMOUNT
    IntOp $UnOptionsY $UnOptionsY + ${AMOUNT}
    IntFmt $UnOptionsYUnit "%uu" $UnOptionsY
!macroend

Function un.UninstallOptionsCreate
    !insertmacro MUI_HEADER_TEXT "$(C13_UNINSTALL_OPTIONS_TITLE)" "$(C13_UNINSTALL_OPTIONS_SUBTITLE)"

    StrCpy $UnRemoveStartMenu "1"
    StrCpy $UnRemoveDesktop "1"
    StrCpy $UnRemoveLaunchers "1"
    StrCpy $UnRemoveVsCodeDataCheckbox ""
    StrCpy $UnRemoveXamppHtdocsCheckbox ""
    StrCpy $UnRemoveXamppMysqlDataCheckbox ""
    ; StrCpy $UnRemoveOpenSshKeysCheckbox ""

    nsDialogs::Create 1018
    Pop $0
    ${If} $0 == error
        Abort
    ${EndIf}

    ${NSD_CreateLabel} 0u 0u 100% 22u "$(C13_UNINSTALL_OPTIONS_INFO)"
    Pop $0

    StrCpy $UnOptionsY 24
    StrCpy $UnOptionsYUnit "24u"

    ${NSD_CreateCheckbox} 0u $UnOptionsYUnit 100% 12u "$(C13_UNINSTALL_CACHE)"
    Pop $UnRemoveCacheCheckbox
    ${NSD_Uncheck} $UnRemoveCacheCheckbox
    !insertmacro C13_AdvanceY 12

    ${NSD_CreateCheckbox} 0u $UnOptionsYUnit 100% 12u "$(C13_UNINSTALL_LOGS)"
    Pop $UnRemoveLogsCheckbox
    ${NSD_Uncheck} $UnRemoveLogsCheckbox
    !insertmacro C13_AdvanceY 12

    ${If} ${FileExists} "$INSTDIR\${VSCODE_INSTALL_DIR}\data\*.*"
        ${NSD_CreateCheckbox} 0u $UnOptionsYUnit 100% 12u "$(C13_UNINSTALL_VSCODE_DATA)"
        Pop $UnRemoveVsCodeDataCheckbox
        ${NSD_Uncheck} $UnRemoveVsCodeDataCheckbox
        !insertmacro C13_AdvanceY 12
    ${EndIf}

    ${If} ${FileExists} "$INSTDIR\${XAMPP_INSTALL_DIR}\htdocs\*.*"
        ${NSD_CreateCheckbox} 0u $UnOptionsYUnit 100% 12u "$(C13_UNINSTALL_XAMPP_HTDOCS)"
        Pop $UnRemoveXamppHtdocsCheckbox
        ${NSD_Uncheck} $UnRemoveXamppHtdocsCheckbox
        !insertmacro C13_AdvanceY 12
    ${EndIf}

    ${If} ${FileExists} "$INSTDIR\${XAMPP_INSTALL_DIR}\mysql\data\*.*"
        ${NSD_CreateCheckbox} 0u $UnOptionsYUnit 100% 12u "$(C13_UNINSTALL_XAMPP_MYSQL)"
        Pop $UnRemoveXamppMysqlDataCheckbox
        ${NSD_Uncheck} $UnRemoveXamppMysqlDataCheckbox
        !insertmacro C13_AdvanceY 12
    ${EndIf}

    ; ${If} ${FileExists} "$INSTDIR\${OPENSSH_INSTALL_DIR}\.ssh\*.*"
    ;     ${NSD_CreateCheckbox} 0u $UnOptionsYUnit 100% 12u "$(C13_UNINSTALL_OPENSSH_KEYS)"
    ;     Pop $UnRemoveOpenSshKeysCheckbox
    ;     ${NSD_Uncheck} $UnRemoveOpenSshKeysCheckbox
    ;     !insertmacro C13_AdvanceY 12
    ; ${EndIf}

    ${NSD_CreateCheckbox} 0u 118u 100% 24u "$(C13_UNINSTALL_INSTALL_DIR)"
    Pop $UnRemoveInstallDirCheckbox
    ${NSD_Uncheck} $UnRemoveInstallDirCheckbox
    ${NSD_OnClick} $UnRemoveInstallDirCheckbox un.UpdateUninstallOptions

    nsDialogs::Show
FunctionEnd

Function un.UninstallOptionsLeave
    StrCpy $UnRemoveStartMenu "1"
    StrCpy $UnRemoveDesktop "1"
    StrCpy $UnRemoveLaunchers "1"

    ${NSD_GetState} $UnRemoveInstallDirCheckbox $0
    ${If} $0 == ${BST_CHECKED}
        MessageBox MB_ICONEXCLAMATION|MB_OKCANCEL "$(C13_UNINSTALL_INSTALL_DIR_CONFIRM)" IDOK +2
        Abort
        StrCpy $UnRemoveInstallDir "1"
        StrCpy $UnRemoveCache "1"
        StrCpy $UnRemoveLogs "1"
        StrCpy $UnRemoveVsCodeData "1"
        StrCpy $UnRemoveXamppHtdocs "1"
        StrCpy $UnRemoveXamppMysqlData "1"
        ; StrCpy $UnRemoveOpenSshKeys "1"
        Return
    ${Else}
        StrCpy $UnRemoveInstallDir "0"
    ${EndIf}

    ${NSD_GetState} $UnRemoveCacheCheckbox $0
    ${If} $0 == ${BST_CHECKED}
        StrCpy $UnRemoveCache "1"
    ${Else}
        StrCpy $UnRemoveCache "0"
    ${EndIf}

    ${NSD_GetState} $UnRemoveLogsCheckbox $0
    ${If} $0 == ${BST_CHECKED}
        StrCpy $UnRemoveLogs "1"
    ${Else}
        StrCpy $UnRemoveLogs "0"
    ${EndIf}

    ${If} $UnRemoveVsCodeDataCheckbox != ""
        ${NSD_GetState} $UnRemoveVsCodeDataCheckbox $0
        ${If} $0 == ${BST_CHECKED}
            StrCpy $UnRemoveVsCodeData "1"
        ${Else}
            StrCpy $UnRemoveVsCodeData "0"
        ${EndIf}
    ${Else}
        StrCpy $UnRemoveVsCodeData "0"
    ${EndIf}

    ${If} $UnRemoveXamppHtdocsCheckbox != ""
        ${NSD_GetState} $UnRemoveXamppHtdocsCheckbox $0
        ${If} $0 == ${BST_CHECKED}
            StrCpy $UnRemoveXamppHtdocs "1"
        ${Else}
            StrCpy $UnRemoveXamppHtdocs "0"
        ${EndIf}
    ${Else}
        StrCpy $UnRemoveXamppHtdocs "0"
    ${EndIf}

    ${If} $UnRemoveXamppMysqlDataCheckbox != ""
        ${NSD_GetState} $UnRemoveXamppMysqlDataCheckbox $0
        ${If} $0 == ${BST_CHECKED}
            MessageBox MB_ICONEXCLAMATION|MB_OKCANCEL "$(C13_UNINSTALL_MYSQL_CONFIRM)" IDOK +2
            Abort
            StrCpy $UnRemoveXamppMysqlData "1"
        ${Else}
            StrCpy $UnRemoveXamppMysqlData "0"
        ${EndIf}
    ${Else}
        StrCpy $UnRemoveXamppMysqlData "0"
    ${EndIf}

    ; ${If} $UnRemoveOpenSshKeysCheckbox != ""
    ;     ${NSD_GetState} $UnRemoveOpenSshKeysCheckbox $0
    ;     ${If} $0 == ${BST_CHECKED}
    ;         MessageBox MB_ICONEXCLAMATION|MB_OKCANCEL "$(C13_UNINSTALL_OPENSSH_CONFIRM)" IDOK +2
    ;         Abort
    ;         StrCpy $UnRemoveOpenSshKeys "1"
    ;     ${Else}
    ;         StrCpy $UnRemoveOpenSshKeys "0"
    ;     ${EndIf}
    ; ${Else}
    ;     StrCpy $UnRemoveOpenSshKeys "0"
    ; ${EndIf}
FunctionEnd

Function un.onInit
    StrCpy $UnRemoveCache "0"
    StrCpy $UnRemoveLogs "0"
    StrCpy $UnRemoveInstallDir "0"
    StrCpy $UnRemoveStartMenu "1"
    StrCpy $UnRemoveDesktop "1"
    StrCpy $UnRemoveLaunchers "1"
    StrCpy $UnRemoveVsCodeData "0"
    StrCpy $UnRemoveXamppHtdocs "0"
    StrCpy $UnRemoveXamppMysqlData "0"
    ; StrCpy $UnRemoveOpenSshKeys "0"
FunctionEnd

Section "Uninstall"
    SetShellVarContext current
    SetOutPath "$TEMP"

    StrCpy $StartMenuDir "$SMPROGRAMS\${APP_START_MENU_FOLDER}"

    ${If} $UnRemoveStartMenu == "1"
        !insertmacro QuietDelete "$StartMenuDir\Codex 13 Launcher.lnk"
        !insertmacro QuietDelete "$StartMenuDir\Codex 13 Student Dev Kit.lnk"
        !insertmacro QuietDelete "$StartMenuDir\Codex 13 Visual Studio Code.lnk"
        !insertmacro QuietDelete "$StartMenuDir\Codex 13 Git Bash.lnk"
        !insertmacro QuietDelete "$StartMenuDir\Codex 13 Git CMD.lnk"
        !insertmacro QuietDelete "$StartMenuDir\Codex 13 XAMPP Control Panel.lnk"
        !insertmacro QuietDelete "$StartMenuDir\$(C13_SHORTCUT_OPEN_INSTALL_DIR).lnk"
        !insertmacro QuietDelete "$StartMenuDir\$(C13_SHORTCUT_UNINSTALL).lnk"
        !insertmacro QuietDelete "$StartMenuDir\Visual Studio Code.lnk"
        !insertmacro QuietDelete "$StartMenuDir\Git Bash.lnk"
        !insertmacro QuietDelete "$StartMenuDir\Git CMD.lnk"
        !insertmacro QuietDelete "$StartMenuDir\XAMPP Control Panel.lnk"
        !insertmacro QuietDelete "$StartMenuDir\Open installation folder.lnk"
        !insertmacro QuietDelete "$StartMenuDir\Show installation log.lnk"
        !insertmacro QuietDelete "$StartMenuDir\Uninstall Codex 13 Student Dev Kit.lnk"
        !insertmacro QuietDelete "$StartMenuDir\Odinstaluj ${APP_NAME}.lnk"
        !insertmacro QuietDelete "$StartMenuDir\$(C13_SHORTCUT_OPEN_SITE).url"
        !insertmacro QuietDelete "$StartMenuDir\Codex 13.url"
        !insertmacro QuietDelete "$StartMenuDir\Codex13.url"
        !insertmacro QuietDelete "$StartMenuDir\Codex 13 phpMyAdmin.url"
        !insertmacro QuietDelete "$StartMenuDir\phpMyAdmin.url"
        RMDir "$StartMenuDir"
    ${EndIf}

    ${If} $UnRemoveDesktop == "1"
        !insertmacro QuietDelete "$DESKTOP\Codex 13 Launcher.lnk"
        !insertmacro QuietDelete "$DESKTOP\Codex 13 Student Dev Kit.lnk"
        !insertmacro QuietDelete "$DESKTOP\Codex 13 Visual Studio Code.lnk"
        !insertmacro QuietDelete "$DESKTOP\Codex 13 Git Bash.lnk"
        !insertmacro QuietDelete "$DESKTOP\Codex 13 Git CMD.lnk"
        !insertmacro QuietDelete "$DESKTOP\Codex 13 XAMPP Control Panel.lnk"
        !insertmacro QuietDelete "$DESKTOP\Visual Studio Code.lnk"
        !insertmacro QuietDelete "$DESKTOP\Git Bash.lnk"
        !insertmacro QuietDelete "$DESKTOP\Git CMD.lnk"
        !insertmacro QuietDelete "$DESKTOP\XAMPP Control Panel.lnk"
        !insertmacro QuietDelete "$DESKTOP\Codex 13.url"
        !insertmacro QuietDelete "$DESKTOP\Codex13.url"
        !insertmacro QuietDelete "$DESKTOP\Codex 13 phpMyAdmin.url"
        !insertmacro QuietDelete "$DESKTOP\phpMyAdmin.url"
    ${EndIf}

    DeleteRegKey HKCU "${UNINSTALL_REG_KEY}"
    DeleteRegKey HKCU "${APP_SETTINGS_REG_KEY}"

    ${If} $UnRemoveInstallDir == "1"
        DetailPrint "$(C13_DETAIL_REMOVE_INSTALL_DIR) $INSTDIR"
        !insertmacro QuietDelete "$INSTDIR\Uninstall.exe"
        !insertmacro QuietRMDir "$INSTDIR"
        RMDir "$INSTDIR"
        Goto uninstall_done
    ${EndIf}

    !insertmacro QuietRMDir "$INSTDIR\${BIN_DIR_NAME}"
    !insertmacro QuietRMDir "$INSTDIR\${GIT_INSTALL_DIR}"

    ${If} $UnRemoveVsCodeData == "1"
        !insertmacro QuietRMDir "$INSTDIR\${VSCODE_INSTALL_DIR}"
    ${Else}
        !insertmacro QuietRMDir "$TEMP\Codex13SdkUninstall\vscode-data"
        ${If} ${FileExists} "$INSTDIR\${VSCODE_INSTALL_DIR}\data\*.*"
            CreateDirectory "$TEMP\Codex13SdkUninstall"
            Rename "$INSTDIR\${VSCODE_INSTALL_DIR}\data" "$TEMP\Codex13SdkUninstall\vscode-data"
        ${EndIf}
        !insertmacro QuietRMDir "$INSTDIR\${VSCODE_INSTALL_DIR}"
        ${If} ${FileExists} "$TEMP\Codex13SdkUninstall\vscode-data\*.*"
            CreateDirectory "$INSTDIR\${VSCODE_INSTALL_DIR}"
            Rename "$TEMP\Codex13SdkUninstall\vscode-data" "$INSTDIR\${VSCODE_INSTALL_DIR}\data"
            DetailPrint "$(C13_DETAIL_VSCODE_DATA_PRESERVED) $INSTDIR\${VSCODE_INSTALL_DIR}\data"
        ${EndIf}
    ${EndIf}

    ; ${If} $UnRemoveOpenSshKeys == "1"
    ;     !insertmacro QuietRMDir "$INSTDIR\${OPENSSH_INSTALL_DIR}"
    ; ${Else}
    ;     !insertmacro QuietRMDir "$TEMP\Codex13SdkUninstall\openssh-ssh"
    ;     ${If} ${FileExists} "$INSTDIR\${OPENSSH_INSTALL_DIR}\.ssh\*.*"
    ;         CreateDirectory "$TEMP\Codex13SdkUninstall"
    ;         Rename "$INSTDIR\${OPENSSH_INSTALL_DIR}\.ssh" "$TEMP\Codex13SdkUninstall\openssh-ssh"
    ;     ${EndIf}
    ;     !insertmacro QuietRMDir "$INSTDIR\${OPENSSH_INSTALL_DIR}"
    ;     ${If} ${FileExists} "$TEMP\Codex13SdkUninstall\openssh-ssh\*.*"
    ;         CreateDirectory "$INSTDIR\${OPENSSH_INSTALL_DIR}"
    ;         Rename "$TEMP\Codex13SdkUninstall\openssh-ssh" "$INSTDIR\${OPENSSH_INSTALL_DIR}\.ssh"
    ;         DetailPrint "$(C13_DETAIL_OPENSSH_PRESERVED)"
    ;     ${EndIf}
    ; ${EndIf}

    !insertmacro QuietRMDir "$TEMP\Codex13SdkUninstall\xampp-htdocs"
    !insertmacro QuietRMDir "$TEMP\Codex13SdkUninstall\xampp-mysql-data"
    ${If} $UnRemoveXamppHtdocs != "1"
    ${AndIf} ${FileExists} "$INSTDIR\${XAMPP_INSTALL_DIR}\htdocs\*.*"
        CreateDirectory "$TEMP\Codex13SdkUninstall"
        Rename "$INSTDIR\${XAMPP_INSTALL_DIR}\htdocs" "$TEMP\Codex13SdkUninstall\xampp-htdocs"
    ${EndIf}
    ${If} $UnRemoveXamppMysqlData != "1"
    ${AndIf} ${FileExists} "$INSTDIR\${XAMPP_INSTALL_DIR}\mysql\data\*.*"
        CreateDirectory "$TEMP\Codex13SdkUninstall"
        Rename "$INSTDIR\${XAMPP_INSTALL_DIR}\mysql\data" "$TEMP\Codex13SdkUninstall\xampp-mysql-data"
    ${EndIf}
    !insertmacro QuietRMDir "$INSTDIR\${XAMPP_INSTALL_DIR}"
    ${If} ${FileExists} "$TEMP\Codex13SdkUninstall\xampp-htdocs\*.*"
        CreateDirectory "$INSTDIR\${XAMPP_INSTALL_DIR}"
        Rename "$TEMP\Codex13SdkUninstall\xampp-htdocs" "$INSTDIR\${XAMPP_INSTALL_DIR}\htdocs"
        DetailPrint "$(C13_DETAIL_XAMPP_HTDOCS_PRESERVED) $INSTDIR\${XAMPP_INSTALL_DIR}\htdocs"
    ${EndIf}
    ${If} ${FileExists} "$TEMP\Codex13SdkUninstall\xampp-mysql-data\*.*"
        CreateDirectory "$INSTDIR\${XAMPP_INSTALL_DIR}\mysql"
        Rename "$TEMP\Codex13SdkUninstall\xampp-mysql-data" "$INSTDIR\${XAMPP_INSTALL_DIR}\mysql\data"
        DetailPrint "$(C13_DETAIL_XAMPP_MYSQL_PRESERVED) $INSTDIR\${XAMPP_INSTALL_DIR}\mysql\data"
    ${EndIf}

    ${If} $UnRemoveCache == "1"
        !insertmacro QuietRMDir "$INSTDIR\${PACKAGES_DIR_NAME}"
    ${Else}
        DetailPrint "$(C13_DETAIL_PACKAGES_PRESERVED) $INSTDIR\${PACKAGES_DIR_NAME}"
    ${EndIf}

    ${If} $UnRemoveLogs == "1"
        !insertmacro QuietRMDir "$INSTDIR\${LOGS_DIR_NAME}"
    ${Else}
        DetailPrint "$(C13_DETAIL_LOGS_PRESERVED) $INSTDIR\${LOGS_DIR_NAME}"
    ${EndIf}

    !insertmacro QuietDelete "$INSTDIR\Uninstall.exe"
    !insertmacro QuietRMDir "$INSTDIR\legal"
    !insertmacro QuietRMDir "$INSTDIR\licenses"
    !insertmacro QuietDelete "$INSTDIR\.gitkeep"
    !insertmacro QuietDelete "$INSTDIR\README.md"
    !insertmacro QuietDelete "$INSTDIR\${MANIFEST_FILE_NAME}"
    !insertmacro QuietDelete "$INSTDIR\codex13-sdk-manifest.json"
    !insertmacro QuietDelete "$INSTDIR\student-dev-kit.json"
    !insertmacro QuietDelete "$INSTDIR\manifest.json"
    RMDir "$INSTDIR\${TOOLS_DIR_NAME}"
    RMDir "$TEMP\Codex13SdkUninstall"
    RMDir "$INSTDIR"

    uninstall_done:
SectionEnd
