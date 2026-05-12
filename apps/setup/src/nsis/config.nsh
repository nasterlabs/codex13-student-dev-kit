!define APP_NAME "Codex 13 Student Dev Kit"
!define APP_PUBLISHER "Naster Labs"
!ifndef APP_EXE_NAME
!define APP_EXE_NAME "Codex13SDK-Setup.exe"
!endif
!define APP_INTERNAL_NAME "Codex13SDKSetup"
!define APP_REGISTRY_KEY "Codex13SDK"
!define APP_SETTINGS_REG_KEY "Software\NasterLabs\Codex13SDK"
!define APP_START_MENU_FOLDER "Codex 13 Student Dev Kit"
!define APP_VERSION "0.7.1"
!ifndef APP_VERSION_QUAD
!define APP_VERSION_QUAD "${APP_VERSION}.0"
!endif
!define LANG_VERSION_POLISH 1045
!define LANG_VERSION_ENGLISH 1033
!include "i18n\version-pl.nsh"
!include "i18n\version-en.nsh"
!define APP_WEBSITE "https://codex13.dev/"
!define APP_OPEN_URL "https://codex13.dev/"
!ifndef BUILD_CHANNEL
!define BUILD_CHANNEL "release"
!endif
!ifndef BUILD_VERSION
!define BUILD_VERSION "${APP_VERSION}-alpha.local"
!endif

!define DEFAULT_INSTALL_DIR "$LOCALAPPDATA\Codex13\StudentDevKit"
!define MANIFEST_FILE_NAME "codex13-sdk.manifest.json"
!define UNATTENDED_FILE_NAME "codex13-sdk.unattended.ini"
!define TOOLS_DIR_NAME "tools"
!define PACKAGES_DIR_NAME "packages"
!define BIN_DIR_NAME "bin"
!define LOGS_DIR_NAME "logs"
!define ASSETS_DIR_NAME "assets"
!define VSCODE_INSTALL_DIR "${TOOLS_DIR_NAME}\VSCode"
!define GIT_INSTALL_DIR "${TOOLS_DIR_NAME}\Git"
!define OPENSSH_INSTALL_DIR "${TOOLS_DIR_NAME}\OpenSSH-Win64"
!define XAMPP_INSTALL_DIR "${TOOLS_DIR_NAME}\xampp"
!define VSCODE_EXE_REL "${VSCODE_INSTALL_DIR}\Code.exe"
!define GIT_BASH_EXE_REL "${GIT_INSTALL_DIR}\git-bash.exe"
!define GIT_CMD_EXE_REL "${GIT_INSTALL_DIR}\git-cmd.exe"
!define OPENSSH_SSH_EXE_REL "${OPENSSH_INSTALL_DIR}\ssh.exe"
!define XAMPP_CONTROL_EXE_REL "${XAMPP_INSTALL_DIR}\xampp-control.exe"
!define PHPMYADMIN_ICON_REL "${XAMPP_INSTALL_DIR}\phpMyAdmin\favicon.ico"
!define CODEX13_ICON_REL "${ASSETS_DIR_NAME}\codex13.ico"

!define VSCODE_VERSION "1.118.1"
!define VSCODE_URL "https://update.code.visualstudio.com/${VSCODE_VERSION}/win32-x64-archive/stable"
!define VSCODE_SHA256 "167B6E9678B2F64D59BFB8E0E682CEB7F8684D4F0106F176219BE852463DB0D3"
!define VSCODE_SIZE_KB 450000

!define GIT_VERSION "2.54.0"
!define GIT_URL "https://github.com/git-for-windows/git/releases/download/v2.54.0.windows.1/PortableGit-2.54.0-64-bit.7z.exe"
!define GIT_SHA256 "BEA006A6CC69673F27B1647E84AB3A68E912FBC175AB6320C5987E012897F311"
!define GIT_SIZE_KB 59000

!define OPENSSH_VERSION "10.0.0.0p2-Preview"
!define OPENSSH_URL "https://github.com/PowerShell/Win32-OpenSSH/releases/download/10.0.0.0p2-Preview/OpenSSH-Win64.zip"
!define OPENSSH_SHA256 "23F50F3458C4C5D0B12217C6A5DDFDE0137210A30FA870E98B29827F7B43ABA5"
!define OPENSSH_SIZE_KB 5600

!define XAMPP_VERSION "8.2.12"
!define XAMPP_URL "https://downloads.sourceforge.net/project/xampp/XAMPP%20Windows/8.2.12/xampp-portable-windows-x64-8.2.12-0-VS16.zip?use_mirror=autoselect"
!define XAMPP_SHA256 "CE3BDF852BD62C7363CB51D66E709B6A9BF5F3EA59BC1712FFDA11D9238E5651"
!define XAMPP_SIZE_KB 1000000

; Codex 13 Setup design tokens. Classic NSIS controls cannot use all of these
; directly, but custom pages and generated assets should stay on this palette.
!define C13_NAVY_950 "0x0B1220"
!define C13_NAVY_900 "0x111827"
!define C13_NAVY_800 "0x1E293B"
!define C13_BLUE_500 "0x3B82F6"
!define C13_BLUE_600 "0x2563EB"
!define C13_CYAN_400 "0x22D3EE"
!define C13_SURFACE "0xF8FAFC"
!define C13_SURFACE_ALT "0xFFFFFF"
!define C13_BORDER "0xCBD5E1"
!define C13_TEXT "0x0F172A"
!define C13_TEXT_MUTED "0x475569"
!define C13_TEXT_SUBTLE "0x64748B"
!define C13_SUCCESS "0x16A34A"
!define C13_WARNING "0xD97706"
!define C13_ERROR "0xDC2626"
