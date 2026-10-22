; claude-to-front.ahk  (AutoHotkey v2)
;
; Brings the Claude desktop window to the front when Windows turns the app's
; activation request into a taskbar flash (the yellow button). That is what
; happens when you click a "Claude replied" toast: the foreground lock denies
; the app's own SetForegroundWindow call, and Windows flashes the taskbar
; button instead. AutoHotkey's WinActivate is allowed to cross that lock.
;
; The window is activated only when ALL of these hold, so the script never
; steals focus on its own (for example when a reply lands while you type):
;   1. the flashing window belongs to the Claude app
;   2. there was keyboard or mouse input within the last IDLE_MS (the click)
;   3. (optional, REQUIRE_TOAST) a notification toast was on screen within TOAST_MS
; Every flash is written to claude-to-front.log next to this script, so a
; miss can be diagnosed from the log.
;
; No keyboard or mouse hook is installed by this script (mousemaster-safe).

; Ported into mm-companion on 2026-10-22: functions and state carry the Front_ prefix, the
; settings sit in companion\settings.ahk, and what ran at load time is now Front_Init().

global Front_lastToastTick := 0
global Front_targetHwnd := 0
global Front_deadline := 0
global Front_did4 := false

Front_Init() {
    global Front_lastToastTick, Front_targetHwnd, Front_deadline, Front_did4
    Log("front", "start")
    SetTimer(Front_WatchToast, 200)
    DllCall("RegisterShellHookWindow", "Ptr", A_ScriptHwnd)
    OnMessage(DllCall("RegisterWindowMessage", "Str", "SHELLHOOK"), Front_OnShellHook)
}

Front_WatchToast() {
    global Front_lastToastTick
    if WinExist("ahk_class Windows.UI.Core.CoreWindow ahk_exe ShellExperienceHost.exe")
        Front_lastToastTick := A_TickCount
}

Front_OnShellHook(wParam, lParam, msg, hwnd) {
    static HSHELL_FLASH := 0x8006
    global Front_targetHwnd, Front_deadline, Front_did4
    if (wParam != HSHELL_FLASH)
        return
    hwndFlash := lParam
    exe := "?"
    title := "?"
    try {
        exe := WinGetProcessName("ahk_id " hwndFlash)
    }
    try {
        title := WinGetTitle("ahk_id " hwndFlash)
    }
    isClaude := (SubStr(StrLower(exe), 1, 6) = "claude") || InStr(title, "Claude")
    idle := A_TimeIdle
    if (Front_targetHwnd = hwndFlash)   ; already working on this burst; the timer handles it
        return
    Log("front", Format("flash exe={} title=[{}] claude={} idle={}ms fg={}", exe, title, isClaude ? 1 : 0, idle, Front_Foreground()))
    if isClaude
        Log("front", "  before: " Front_Diag(hwndFlash))
    if !isClaude
        return
    if (idle > Front_IdleMs) {
        Log("front", "skip: no recent input")
        return
    }
    ; At the moment of the flash the foreground is still the toast host
    ; (ShellExperienceHost, a Modern app), and while a Modern app is in the
    ; foreground nobody may take it. So poll: wait for the toast to go away,
    ; then activate. Give up after Front_RetryMs.
    Front_targetHwnd := hwndFlash
    Front_deadline := A_TickCount + Front_RetryMs
    Front_did4 := false
    SetTimer(Front_TryActivate, 100)
}

Front_Foreground() {
    try {
        return WinGetProcessName("A") " [" WinGetTitle("A") "]"
    } catch {
        return "(none)"
    }
}

Front_TryActivate() {
    global Front_targetHwnd, Front_deadline, Front_did4
    hwndT := Front_targetHwnd
    if WinActive("ahk_id " hwndT) {
        Log("front", "active now (fg=" Front_Foreground() ")")
        Log("front", "  after: " Front_Diag(hwndT))
        SetTimer(Front_TryActivate, 0), Front_targetHwnd := 0
        return
    }
    if (A_TickCount > Front_deadline) {
        Log("front", "FAILED after " Front_RetryMs "ms, fg=" Front_Foreground())
        SetTimer(Front_TryActivate, 0), Front_targetHwnd := 0
        return
    }
    fgExe := ""
    try {
        fgExe := StrLower(WinGetProcessName("A"))
    }
    if (fgExe = "shellexperiencehost.exe")
        return   ; toast still up: wait
    mm := 0
    try mm := WinGetMinMax("ahk_id " hwndT)
    if (mm = -1) {
        try WinRestore("ahk_id " hwndT)
    }
    ; 1. The classic unlock: a tap of Alt makes Windows allow the next
    ;    SetForegroundWindow. The tap is tagged with mousemaster's own
    ;    injected-event signature (dwExtraInfo 0x4D4D4B42) so mousemaster's
    ;    hook passes it through instead of treating it as a combo key.
    Front_TapAltTagged()
    DllCall("SetForegroundWindow", "Ptr", hwndT)
    Sleep(50)
    if WinActive("ahk_id " hwndT) {
        Front_Done("tagged alt + SetForegroundWindow (fg was " fgExe ")", hwndT)
        return
    }
    ; 2. Become the process that received the last input event: a tiny
    ;    near-invisible window of our own is shown under the cursor and
    ;    clicked (SendInput). The click makes this script the foreground
    ;    process, and a foreground process may hand the foreground to anyone.
    ;    The click is verified to land on our own window before it is sent.
    if Front_ClickSelf() {
        DllCall("SetForegroundWindow", "Ptr", hwndT)
        Sleep(50)
        if WinActive("ahk_id " hwndT) {
            Front_Done("self-click + SetForegroundWindow (fg was " fgExe ")", hwndT)
            return
        }
    }
    ; 3. SwitchToThisWindow (alt-tab path)
    try DllCall("SwitchToThisWindow", "Ptr", hwndT, "Int", 1)
    Sleep(50)
    if WinActive("ahk_id " hwndT) {
        Front_Done("SwitchToThisWindow (fg was " fgExe ")", hwndT)
        return
    }
    ; 4. WinActivate (SetForegroundWindow, AttachThreadInput, untagged alt trick)
    try WinActivate("ahk_id " hwndT)
    Sleep(50)
    if WinActive("ahk_id " hwndT) {
        Front_Done("WinActivate (fg was " fgExe ")", hwndT)
        return
    }
    ; 5. minimize / restore (once per burst, it is visible)
    if Front_did4
        return
    Front_did4 := true
    try {
        WinMinimize("ahk_id " hwndT)
        Sleep(80)
        WinRestore("ahk_id " hwndT)
        Sleep(60)
        DllCall("SetForegroundWindow", "Ptr", hwndT)
    }
    Sleep(50)
    if WinActive("ahk_id " hwndT) {
        Front_Done("minimize/restore (fg was " fgExe ")", hwndT)
        return
    }
    ; else: try again on the next tick
}

Front_Done(reason, hwndT) {
    global Front_targetHwnd
    Log("front", "activated by " reason)
    Log("front", "  after: " Front_Diag(hwndT))
    ; Active but on another virtual desktop (cloaked): bring it to this desktop.
    if (Front_IsOnCurrentDesktop(hwndT) = 0) {
        ref := 0
        try ref := WinExist("A")
        moved := Front_MoveToDesktopOf(hwndT, ref)
        Sleep(100)
        DllCall("SetForegroundWindow", "Ptr", hwndT)
        Sleep(60)
        Log("front", "  moved to current desktop=" (moved ? 1 : 0) " -> " Front_Diag(hwndT))
    }
    SetTimer(Front_TryActivate, 0), Front_targetHwnd := 0
}

Front_Diag(hwnd) {
    vis := DllCall("IsWindowVisible", "Ptr", hwnd)
    cloaked := 0
    try DllCall("dwmapi\DwmGetWindowAttribute", "Ptr", hwnd, "UInt", 14, "UInt*", &cloaked, "UInt", 4)
    mm := "?"
    try mm := WinGetMinMax("ahk_id " hwnd)
    x := y := w := h := 0
    try WinGetPos(&x, &y, &w, &h, "ahk_id " hwnd)
    cx := x + w // 2, cy := y + h // 2
    top := "?"
    try {
        hTop := DllCall("WindowFromPoint", "Int64", (cy << 32) | (cx & 0xFFFFFFFF), "Ptr")
        hTop := DllCall("GetAncestor", "Ptr", hTop, "UInt", 2, "Ptr")
        top := (hTop = hwnd) ? "itself" : WinGetProcessName("ahk_id " hTop) "[" WinGetTitle("ahk_id " hTop) "]"
    }
    return Format("active={} visible={} cloaked={} minmax={} rect={},{} {}x{} ondesk={} topAtCenter={}",
        WinActive("ahk_id " hwnd) ? 1 : 0, vis, cloaked, mm, x, y, w, h, Front_IsOnCurrentDesktop(hwnd), top)
}

Front_GetVDM() {
    static vdm := ""
    if (vdm = "") {
        try vdm := ComObject("{AA509086-5CA9-4C25-8F95-589D3C07B48A}", "{A5CD92FF-29BE-454C-8D04-D82879FB3F1B}")
        catch {
            vdm := 0
        }
    }
    return vdm
}

Front_IsOnCurrentDesktop(hwnd) {
    vdm := Front_GetVDM()
    if !vdm
        return -1
    on := 0
    try {
        ComCall(3, vdm, "Ptr", hwnd, "Int*", &on)
        return on ? 1 : 0
    } catch {
        return -1
    }
}

Front_MoveToDesktopOf(hwnd, hwndRef) {
    vdm := Front_GetVDM()
    if (!vdm || !hwndRef)
        return false
    guid := Buffer(16, 0)
    try {
        ComCall(4, vdm, "Ptr", hwndRef, "Ptr", guid)
        ComCall(5, vdm, "Ptr", hwnd, "Ptr", guid)
        return true
    } catch {
        return false
    }
}

Front_ClickSelf() {
    MouseGetPos(&mx, &my)
    g := Gui("+AlwaysOnTop -Caption +ToolWindow", "claude-to-front")
    g.BackColor := "000000"
    ok := false
    try {
        g.Show("x" (mx - 3) " y" (my - 3) " w7 h7 NoActivate")
        WinSetTransparent(1, "ahk_id " g.Hwnd)
        Sleep(30)
        hUnder := DllCall("WindowFromPoint", "Int64", (my << 32) | (mx & 0xFFFFFFFF), "Ptr")
        hUnder := DllCall("GetAncestor", "Ptr", hUnder, "UInt", 2, "Ptr")
        if (hUnder = g.Hwnd) {
            Front_ClickTagged()
            Sleep(40)
            ok := WinActive("ahk_id " g.Hwnd) ? true : false
            Log("front", "  self-click: our window is foreground=" (ok ? 1 : 0))
        } else {
            Log("front", "  self-click skipped: cursor is over " Front_Foreground())
        }
    } catch as e {
        Log("front", "  self-click error: " e.Message)
    }
    try g.Destroy()
    return ok
}

Front_ClickTagged() {
    ; SendInput left button down + up at the current position, dwExtraInfo tagged.
    static SIG := 0x4D4D4B42, LEFTDOWN := 0x0002, LEFTUP := 0x0004
    buf := Buffer(80, 0)
    NumPut("UInt", 0, buf, 0)                 ; INPUT_MOUSE
    NumPut("UInt", LEFTDOWN, buf, 20)
    NumPut("UPtr", SIG, buf, 32)
    NumPut("UInt", 0, buf, 40)
    NumPut("UInt", LEFTUP, buf, 60)
    NumPut("UPtr", SIG, buf, 72)
    n := DllCall("SendInput", "UInt", 2, "Ptr", buf, "Int", 40, "UInt")
    if (n != 2)
        Log("front", "  SendInput(mouse) sent " n " of 2 (err " A_LastError ")")
}

Front_TapAltTagged() {
    ; SendInput of VK_LMENU down + up, dwExtraInfo = 0x4D4D4B42 (mousemaster's
    ; MOUSEMASTER_INJECTED_EVENT_SIGNATURE), INPUT is 40 bytes on x64.
    static SIG := 0x4D4D4B42, VK_LMENU := 0xA4, SC_LALT := 0x38, KEYEVENTF_KEYUP := 2
    buf := Buffer(80, 0)
    NumPut("UInt", 1, buf, 0)                 ; INPUT_KEYBOARD
    NumPut("UShort", VK_LMENU, buf, 8)
    NumPut("UShort", SC_LALT, buf, 10)
    NumPut("UInt", 0, buf, 12)
    NumPut("UPtr", SIG, buf, 24)
    NumPut("UInt", 1, buf, 40)
    NumPut("UShort", VK_LMENU, buf, 48)
    NumPut("UShort", SC_LALT, buf, 50)
    NumPut("UInt", KEYEVENTF_KEYUP, buf, 52)
    NumPut("UPtr", SIG, buf, 64)
    n := DllCall("SendInput", "UInt", 2, "Ptr", buf, "Int", 40, "UInt")
    if (n != 2)
        Log("front", "SendInput sent " n " of 2 (err " A_LastError ")")
}
