// SPDX-License-Identifier: MIT
//
// Copyright (c) 2026 Naster Labs (a brand of Luczak Consulting P.S.A.)
//
// NSIS Naster Archive - NSIS plug-in for archive operations.

#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <commctrl.h>

#include <algorithm>
#include <cwctype>
#include <string>
#include <vector>

#include "resource.h"
#include "nsis-plugin-api/pluginapi.h"

#define PB_RANGE 400

namespace {

HINSTANCE g_instance = nullptr;

struct Options {
  bool nsisdl = false;
  std::wstring sevenZipPath;
  std::wstring caption = L"Extracting archive";
  std::wstring text = L"Extracting archive... please wait.";
  std::wstring cancelText;
  std::wstring question = L"Cancel extraction?";
  std::wstring archivePath;
  std::wstring destinationDir;
  std::vector<std::wstring> excludes;
};

struct SharedState {
  CRITICAL_SECTION lock;
  bool done = false;
  bool cancelRequested = false;
  DWORD exitCode = STILL_ACTIVE;
  int percent = 0;
  std::wstring statusText;
  std::wstring errorText;
  PROCESS_INFORMATION process = {};
};

struct ThreadData {
  Options options;
  SharedState *state;
};

bool TryPopArg(std::wstring *value)
{
  std::vector<TCHAR> buffer(g_stringsize);
  if (popstring(buffer.data()) != 0) {
    return false;
  }
  *value = buffer.data();
  return true;
}

void PushResult(const wchar_t *value)
{
  pushstring(value);
}

std::wstring ToUpper(std::wstring value)
{
  std::transform(value.begin(), value.end(), value.begin(), [](wchar_t ch) {
    return static_cast<wchar_t>(std::towupper(ch));
  });
  return value;
}

bool IsSwitch(const std::wstring &value, const wchar_t *name)
{
  return ToUpper(value) == ToUpper(name);
}

bool LooksLikeEnd(const std::wstring &value)
{
  return IsSwitch(value, L"/END");
}

std::wstring QuoteArg(const std::wstring &arg)
{
  std::wstring result = L"\"";
  unsigned int slashes = 0;
  for (wchar_t ch : arg) {
    if (ch == L'\\') {
      ++slashes;
      continue;
    }
    if (ch == L'"') {
      result.append(slashes * 2 + 1, L'\\');
      result.push_back(ch);
      slashes = 0;
      continue;
    }
    result.append(slashes, L'\\');
    slashes = 0;
    result.push_back(ch);
  }
  result.append(slashes * 2, L'\\');
  result.push_back(L'"');
  return result;
}

std::wstring BuildCommandLine(const Options &options)
{
  std::wstring command = QuoteArg(options.sevenZipPath);
  command += L" x -y -bsp1 -bso0 -bse1";
  command += L" -o";
  command += QuoteArg(options.destinationDir);

  for (const std::wstring &exclude : options.excludes) {
    command += L" -x!";
    command += QuoteArg(exclude);
  }

  command += L" ";
  command += QuoteArg(options.archivePath);
  return command;
}

void SetSharedError(SharedState *state, const std::wstring &message)
{
  EnterCriticalSection(&state->lock);
  if (state->errorText.empty()) {
    state->errorText = message;
  }
  LeaveCriticalSection(&state->lock);
}

void SetSharedProgress(SharedState *state, int percent)
{
  percent = max(0, min(100, percent));
  EnterCriticalSection(&state->lock);
  state->percent = percent;
  LeaveCriticalSection(&state->lock);
}

void AppendOutputAndParseProgress(SharedState *state, std::string &pending, const char *buffer, DWORD length)
{
  pending.append(buffer, buffer + length);

  size_t marker = pending.find('%');
  while (marker != std::string::npos) {
    size_t start = marker;
    while (start > 0 && pending[start - 1] >= '0' && pending[start - 1] <= '9') {
      --start;
    }
    if (start < marker) {
      int percent = atoi(pending.substr(start, marker - start).c_str());
      SetSharedProgress(state, percent);
    }
    pending.erase(0, marker + 1);
    marker = pending.find('%');
  }

  if (pending.size() > 256) {
    pending.erase(0, pending.size() - 256);
  }
}

DWORD WINAPI ExtractThread(LPVOID data)
{
  ThreadData *threadData = static_cast<ThreadData *>(data);
  SharedState *state = threadData->state;
  Options options = threadData->options;
  delete threadData;

  SECURITY_ATTRIBUTES security = {};
  security.nLength = sizeof(security);
  security.bInheritHandle = TRUE;

  HANDLE readPipe = nullptr;
  HANDLE writePipe = nullptr;
  if (!CreatePipe(&readPipe, &writePipe, &security, 0)) {
    SetSharedError(state, L"Could not create output pipe.");
    EnterCriticalSection(&state->lock);
    state->done = true;
    state->exitCode = 1;
    LeaveCriticalSection(&state->lock);
    return 1;
  }
  SetHandleInformation(readPipe, HANDLE_FLAG_INHERIT, 0);

  STARTUPINFOW startup = {};
  startup.cb = sizeof(startup);
  startup.dwFlags = STARTF_USESTDHANDLES | STARTF_USESHOWWINDOW;
  startup.hStdOutput = writePipe;
  startup.hStdError = writePipe;
  startup.hStdInput = nullptr;
  startup.wShowWindow = SW_HIDE;

  std::wstring commandLine = BuildCommandLine(options);
  std::vector<wchar_t> commandBuffer(commandLine.begin(), commandLine.end());
  commandBuffer.push_back(L'\0');

  PROCESS_INFORMATION process = {};
  BOOL created = CreateProcessW(
      nullptr,
      commandBuffer.data(),
      nullptr,
      nullptr,
      TRUE,
      CREATE_NO_WINDOW,
      nullptr,
      nullptr,
      &startup,
      &process);
  CloseHandle(writePipe);

  if (!created) {
    CloseHandle(readPipe);
    SetSharedError(state, L"Could not start 7-Zip.");
    EnterCriticalSection(&state->lock);
    state->done = true;
    state->exitCode = GetLastError();
    LeaveCriticalSection(&state->lock);
    return 1;
  }

  bool shouldCancel = false;
  EnterCriticalSection(&state->lock);
  state->process = process;
  shouldCancel = state->cancelRequested;
  LeaveCriticalSection(&state->lock);

  if (shouldCancel) {
    TerminateProcess(process.hProcess, ERROR_CANCELLED);
  }

  char buffer[1024];
  DWORD bytesRead = 0;
  std::string pending;
  while (ReadFile(readPipe, buffer, sizeof(buffer), &bytesRead, nullptr) && bytesRead > 0) {
    AppendOutputAndParseProgress(state, pending, buffer, bytesRead);
  }
  CloseHandle(readPipe);

  WaitForSingleObject(process.hProcess, INFINITE);
  DWORD exitCode = 1;
  GetExitCodeProcess(process.hProcess, &exitCode);
  CloseHandle(process.hThread);
  CloseHandle(process.hProcess);

  EnterCriticalSection(&state->lock);
  state->exitCode = exitCode;
  if (exitCode == 0) {
    state->percent = 100;
  }
  state->done = true;
  LeaveCriticalSection(&state->lock);
  return exitCode;
}

void RequestCancel(HWND dialog, SharedState *state, const Options &options)
{
  if (!options.question.empty()) {
    int answer = MessageBoxW(
        dialog,
        options.question.c_str(),
        options.caption.c_str(),
        MB_ICONWARNING | MB_YESNO | MB_DEFBUTTON2);
    if (answer != IDYES) {
      return;
    }
  }

  EnterCriticalSection(&state->lock);
  state->cancelRequested = true;
  HANDLE process = state->process.hProcess;
  if (process) {
    TerminateProcess(process, ERROR_CANCELLED);
  }
  LeaveCriticalSection(&state->lock);
  DestroyWindow(dialog);
}

INT_PTR CALLBACK ProgressDlgProc(HWND dialog, UINT message, WPARAM wParam, LPARAM lParam)
{
  SharedState *state = reinterpret_cast<SharedState *>(GetWindowLongPtr(dialog, GWLP_USERDATA));
  Options *options = reinterpret_cast<Options *>(GetPropW(dialog, L"nasterarchive.options"));

  switch (message) {
    case WM_INITDIALOG:
      state = reinterpret_cast<SharedState *>(lParam);
      SetWindowLongPtr(dialog, GWLP_USERDATA, reinterpret_cast<LONG_PTR>(state));
      SendDlgItemMessage(dialog, IDC_PROGRESS_BAR, PBM_SETRANGE, 0, MAKELPARAM(0, PB_RANGE));
      SendDlgItemMessage(dialog, IDC_PROGRESS_BAR, PBM_SETPOS, 0, 0);
      SetTimer(dialog, 1, 250, nullptr);
      return FALSE;
    case WM_ERASEBKGND: {
      RECT rect = {};
      GetClientRect(dialog, &rect);
      FillRect(reinterpret_cast<HDC>(wParam), &rect, GetSysColorBrush(COLOR_BTNFACE));
      return TRUE;
    }
    case WM_TIMER:
      if (state) {
        int percent = 0;
        std::wstring status;
        bool done = false;
        EnterCriticalSection(&state->lock);
        percent = state->percent;
        status = state->statusText;
        done = state->done;
        LeaveCriticalSection(&state->lock);

        SendDlgItemMessage(dialog, IDC_PROGRESS_BAR, PBM_SETPOS, percent * PB_RANGE / 100, 0);
        SetDlgItemTextW(dialog, IDC_STATUS_TEXT, status.c_str());
        if (done) {
          DestroyWindow(dialog);
        }
      }
      return TRUE;
    case WM_COMMAND:
      if (LOWORD(wParam) == IDCANCEL && state && options) {
        RequestCancel(dialog, state, *options);
        return TRUE;
      }
      return FALSE;
    case WM_DESTROY:
      KillTimer(dialog, 1);
      RemovePropW(dialog, L"nasterarchive.options");
      return TRUE;
  }
  return FALSE;
}

bool ParseOptions(Options *options, std::wstring *error)
{
  std::vector<std::wstring> args;
  for (;;) {
    std::wstring arg;
    if (!TryPopArg(&arg)) {
      *error = L"Missing /END.";
      return false;
    }
    if (LooksLikeEnd(arg)) {
      break;
    }
    args.push_back(arg);
  }

  auto readOptionValue = [&args, error](size_t *index, const wchar_t *optionName, std::wstring *value) -> bool {
    size_t valueIndex = *index + 1;
    if (valueIndex >= args.size()) {
      *error = L"Missing value for ";
      *error += optionName;
      *error += L".";
      return false;
    }

    *value = args[valueIndex];
    *index = valueIndex;
    return true;
  };

  size_t i = 0;
  while (i < args.size()) {
    const std::wstring &arg = args[i];
    if (IsSwitch(arg, L"/NSISDL")) {
      options->nsisdl = true;
    } else if (IsSwitch(arg, L"/7ZIP")) {
      if (!readOptionValue(&i, L"/7ZIP", &options->sevenZipPath)) {
        return false;
      }
    } else if (IsSwitch(arg, L"/CAPTION")) {
      if (!readOptionValue(&i, L"/CAPTION", &options->caption)) {
        return false;
      }
    } else if (IsSwitch(arg, L"/TEXT")) {
      if (!readOptionValue(&i, L"/TEXT", &options->text)) {
        return false;
      }
    } else if (IsSwitch(arg, L"/CANCELTEXT")) {
      if (!readOptionValue(&i, L"/CANCELTEXT", &options->cancelText)) {
        return false;
      }
    } else if (IsSwitch(arg, L"/QUESTION")) {
      if (!readOptionValue(&i, L"/QUESTION", &options->question)) {
        return false;
      }
    } else if (IsSwitch(arg, L"/EXCLUDE")) {
      std::wstring exclude;
      if (!readOptionValue(&i, L"/EXCLUDE", &exclude)) {
        return false;
      }
      options->excludes.push_back(exclude);
    } else if (arg.size() > 0 && arg[0] == L'/') {
      *error = L"Unsupported option: " + arg;
      return false;
    } else if (options->archivePath.empty()) {
      options->archivePath = arg;
    } else if (options->destinationDir.empty()) {
      options->destinationDir = arg;
    } else {
      *error = L"Too many positional arguments.";
      return false;
    }
    ++i;
  }

  if (options->sevenZipPath.empty()) {
    *error = L"Missing /7ZIP path.";
    return false;
  }
  if (options->archivePath.empty() || options->destinationDir.empty()) {
    *error = L"Missing archive or destination path.";
    return false;
  }
  return true;
}

HWND FindInstFilesInnerDialog(HWND hwndParent)
{
  if (!hwndParent) {
    return nullptr;
  }
  return FindWindowExW(hwndParent, nullptr, L"#32770", nullptr);
}

void PositionNsisdlDialog(HWND child, HWND dialog)
{
  RECT childRect = {};
  RECT dialogRect = {};
  GetClientRect(child, &childRect);
  GetWindowRect(dialog, &dialogRect);

  int dialogWidth = dialogRect.right - dialogRect.left;
  int dialogHeight = dialogRect.bottom - dialogRect.top;
  int x = max(0, ((childRect.right - childRect.left) - dialogWidth) / 2);
  int y = max(0, ((childRect.bottom - childRect.top) - dialogHeight) / 2);

  HWND detailsButton = GetDlgItem(child, 0x403);
  if (detailsButton) {
    RECT detailsRect = {};
    GetWindowRect(detailsButton, &detailsRect);
    POINT detailsBottom = { detailsRect.left, detailsRect.bottom };
    ScreenToClient(child, &detailsBottom);
    y = detailsBottom.y + 45;
  }

  int maxY = max(0, (childRect.bottom - childRect.top) - dialogHeight - 8);
  if (y > maxY) {
    y = maxY;
  }

  SetWindowPos(dialog, HWND_TOP, x, y, 0, 0, SWP_NOSIZE);
}

void RunWithUi(HWND hwndParent, Options &options, SharedState *state)
{
  HWND child = FindInstFilesInnerDialog(hwndParent);
  if (child) {
    SetDlgItemTextW(child, 1006, options.caption.c_str());
    HWND detailsButton = GetDlgItem(child, 0x403);
    HWND detailsList = GetDlgItem(child, 0x3f8);
    DWORD detailsButtonStyle = detailsButton ? GetWindowLong(detailsButton, GWL_STYLE) : 0;
    BOOL detailsListVisible = detailsList ? IsWindowVisible(detailsList) : FALSE;

    if (detailsButton) {
      EnableWindow(detailsButton, FALSE);
    }
    if (detailsList) {
      ShowWindow(detailsList, SW_HIDE);
    }

    HWND dialog = CreateDialogParamW(g_instance, MAKEINTRESOURCEW(IDD_NSISDL_PROGRESS), child, ProgressDlgProc, reinterpret_cast<LPARAM>(state));
    if (dialog) {
      SetPropW(dialog, L"nasterarchive.options", &options);
      HFONT font = reinterpret_cast<HFONT>(SendMessage(child, WM_GETFONT, 0, 0));
      if (font) {
        SendDlgItemMessage(dialog, IDC_STATUS_TEXT, WM_SETFONT, reinterpret_cast<WPARAM>(font), 0);
        SendDlgItemMessage(dialog, IDCANCEL, WM_SETFONT, reinterpret_cast<WPARAM>(font), 0);
      }
      if (!options.cancelText.empty()) {
        SetDlgItemTextW(dialog, IDCANCEL, options.cancelText.c_str());
      }
      PositionNsisdlDialog(child, dialog);
      InvalidateRect(dialog, nullptr, TRUE);
      UpdateWindow(dialog);
      ShowWindow(dialog, SW_SHOW);

      MSG msg;
      while (IsWindow(dialog) && GetMessage(&msg, nullptr, 0, 0) > 0) {
        if (!IsDialogMessage(dialog, &msg) && !IsDialogMessage(hwndParent, &msg)) {
          TranslateMessage(&msg);
          DispatchMessage(&msg);
        }
      }
    }

    if (detailsButton) {
      SetWindowLongPtr(detailsButton, GWL_STYLE, detailsButtonStyle);
      EnableWindow(detailsButton, TRUE);
    }
    if (detailsList && detailsListVisible) {
      ShowWindow(detailsList, SW_SHOW);
    }
    SetDlgItemTextW(child, 1006, L"");
    return;
  }

  while (true) {
    Sleep(100);
    EnterCriticalSection(&state->lock);
    bool done = state->done;
    LeaveCriticalSection(&state->lock);
    if (done) {
      break;
    }
  }
}

}  // namespace

BOOL WINAPI DllMain(HINSTANCE instance, DWORD reason, LPVOID)
{
  if (reason == DLL_PROCESS_ATTACH) {
    g_instance = instance;
    DisableThreadLibraryCalls(instance);
  }
  return TRUE;
}

extern "C" __declspec(dllexport) void __cdecl extract(
    HWND hwndParent,
    int string_size,
    TCHAR *variables,
    stack_t **stacktop,
    extra_parameters *extra)
{
  EXDLL_INIT();
  InitCommonControls();

  Options options;
  std::wstring error;
  if (!ParseOptions(&options, &error)) {
    PushResult(error.c_str());
    return;
  }

  SharedState state;
  InitializeCriticalSection(&state.lock);
  state.statusText = options.text;

  ThreadData *threadData = new ThreadData{options, &state};
  HANDLE thread = CreateThread(nullptr, 0, ExtractThread, threadData, 0, nullptr);
  if (!thread) {
    delete threadData;
    DeleteCriticalSection(&state.lock);
    PushResult(L"Could not start extraction thread.");
    return;
  }

  bool silent = extra && extra->exec_flags && extra->exec_flags->silent;
  if (options.nsisdl && !silent) {
    RunWithUi(hwndParent, options, &state);
  }

  WaitForSingleObject(thread, INFINITE);
  CloseHandle(thread);

  bool cancelled = false;
  DWORD exitCode = 1;
  std::wstring errorText;
  EnterCriticalSection(&state.lock);
  cancelled = state.cancelRequested || state.exitCode == ERROR_CANCELLED;
  exitCode = state.exitCode;
  errorText = state.errorText;
  LeaveCriticalSection(&state.lock);
  DeleteCriticalSection(&state.lock);

  if (cancelled) {
    PushResult(L"cancel");
  } else if (exitCode == 0) {
    PushResult(L"OK");
  } else if (!errorText.empty()) {
    PushResult(errorText.c_str());
  } else {
    wchar_t result[128];
    wsprintfW(result, L"7-Zip exited with code %lu.", exitCode);
    PushResult(result);
  }
}
