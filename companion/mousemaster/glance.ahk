; glance.ahk  (AutoHotkey v2)
;
; w in mousemaster's normal-mode (F16, mousemaster.properties [34]) shows Google
; Calendar as an app window next to the mouse, and hides it again. The window is the
; browser's own "--app=" window of calendar.google.com (a standalone window with no
; tabs: the real Google Calendar, with its own quick-add, reminders and sync), so
; nothing is reimplemented here.
;   w : show next to the mouse (on the monitor the mouse is on) / hide. The window is
;       kept and only hidden, so this is instant. It is launched hidden ahead of time
;       (prewarm, see the settings), so even the first press does not wait for the
;       browser; w before the prewarm launches it visibly (1-2 s).
;   Closing it with its own X is fine: while the browser keeps running, it is launched
;   hidden again a few seconds later.
; Typing in the window: mousemaster's normal-mode letters are mouse commands, so
; leave normal-mode (ctrl+alt) to type, as in any other app, and come back with
; ctrl+alt; w then hides the window.
;
; Settings below: the browser (auto-detected: Brave, then Chrome, Edge), the URL (the
; custom view; set it to 7 days once in Google Calendar's settings, so it shows today and
; the next 6 days), the window size, the prewarm. Events are written to glance.log next
; to this script (no user paths in it).
; Today: the first show of each day presses Google Calendar's own t (today) in the
; window, so the 7 days start today even when the window was loaded days ago. A window
; adopted after this script restarts also gets x (custom view) first.
; The earlier clock + notes window lives on as glance-notes.ahk (optional, with the
; Google Calendar API bridge glance-gcal.ps1 / GLANCE-GCAL-SETUP.md).

; Ported into mm-companion on 2026-10-22: functions and state carry the Glance_ prefix, the
; settings sit in companion\settings.ahk, and what ran at load time is now Glance_Init().

global Glance_calWin := 0             ; hwnd of the calendar window (0 = none known)
global Glance_launching := 0          ; tick count of the launch in progress (0 = none)
global Glance_launchHidden := false   ; the launch in progress is a prewarm: hide the window as soon as it appears
global Glance_knownWindows := Map()   ; browser windows that existed before the launch
global Glance_prevActive := 0         ; window that was active before a prewarm launch (focus is given back)
global Glance_staleWin := 0           ; a window to close once the new one is up (its page never loaded)
global Glance_readyAt := 0            ; tick count when the current window appeared
global Glance_goneSince := 0          ; tick count since the window has been missing
global Glance_lastPrewarm := 0
global Glance_prewarmFailures := 0
global Glance_browserStartAllowed := true
global Glance_startedAt := A_TickCount
global Glance_viewDate := ""          ; day (yyyyMMdd) the view was last set to today ("" = unknown: adopted window)

Glance_Init() {
    global Glance_calWin, Glance_launching, Glance_launchHidden, Glance_knownWindows, Glance_prevActive, Glance_staleWin, Glance_readyAt, Glance_goneSince, Glance_lastPrewarm, Glance_prewarmFailures, Glance_browserStartAllowed, Glance_startedAt, Glance_viewDate
    Log("glance", "start (" A_ScriptName " in " SubStr(A_ScriptDir, InStr(A_ScriptDir, "\", , -1) + 1) ")")   ; folder name only: no user path in the log
    if Glance_FindCalendarWindow()
        Log("glance", "adopted an existing calendar window")
    SetTimer(Glance_Watch, 3000)
    Core_Hotkeys("F16", (*) => Glance_Toggle())
}

Glance_Toggle() {
    global Glance_launching, Glance_launchHidden, Glance_staleWin, Glance_calWin, Glance_readyAt
    h := Glance_FindCalendarWindow()
    if !h {
        if Glance_launching {
            if Glance_launchHidden {
                Glance_launchHidden := false     ; the prewarm in progress is shown as soon as it appears
                Log("glance", "toggle while prewarming: shown when ready")
            } else
                Log("glance", "toggle while Glance_launching: ignored")
            return
        }
        Glance_Launch(false)
        return
    }
    if (DllCall("IsWindowVisible", "ptr", h) && !DllCall("IsIconic", "ptr", h)) {
        WinHide("ahk_id " h)
        Log("glance", "hide")
        return
    }
    ; A title that is still the address 15 s after the window appeared: the page never
    ; loaded (e.g. prewarmed at sign-in before the network was up). A new window
    ; replaces it; the old one is closed once the new one is up, so the browser stays.
    t := ""
    try t := WinGetTitle("ahk_id " h)
    if (A_TickCount - Glance_readyAt > 15000 && RegExMatch(t, "i)^calendar\.google\.com")) {
        Log("glance", "page did not load (title is still the address): new window")
        Glance_staleWin := h, Glance_calWin := 0
        Glance_Launch(false)
        return
    }
    Glance_Place(h)
    WinShow("ahk_id " h)
    try WinActivate("ahk_id " h)
    Log("glance", "show")
    Glance_AlignToToday(h)
}

Glance_FindCalendarWindow() {
    global Glance_calWin
    if (Glance_calWin && WinExist("ahk_id " Glance_calWin) && WinGetClass("ahk_id " Glance_calWin) = "Chrome_WidgetWin_1")
        return Glance_calWin
    Glance_calWin := 0
    for h in WinGetList("ahk_class Chrome_WidgetWin_1") {
        if Glance_IsCalendarTitle(WinGetTitle("ahk_id " h)) {
            Glance_calWin := h
            break
        }
    }
    return Glance_calWin
}

Glance_IsCalendarTitle(t) {
    static jp := "Google " Chr(0x30AB) Chr(0x30EC) Chr(0x30F3) Chr(0x30C0) Chr(0x30FC)
    if (t = "")
        return false
    if !(InStr(t, "Google Calendar") || InStr(t, jp) || InStr(t, "calendar.google.com"))
        return false
    return !RegExMatch(t, "i)- (Google Chrome|Brave|Microsoft\x{200B}? Edge|Chromium)$")
}

Glance_Browser() {
    global Glance_BrowserExe
    if (Glance_BrowserExe != "" && FileExist(Glance_BrowserExe))
        return Glance_BrowserExe
    lad := EnvGet("LOCALAPPDATA")
    pf := A_ProgramFiles
    pf86 := EnvGet("ProgramFiles(x86)")
    for p in [pf "\BraveSoftware\Brave-Glance_Browser\Application\brave.exe",
              lad "\BraveSoftware\Brave-Glance_Browser\Application\brave.exe",
              pf "\Google\Chrome\Application\chrome.exe",
              lad "\Google\Chrome\Application\chrome.exe",
              pf86 "\Microsoft\Edge\Application\msedge.exe",
              pf "\Microsoft\Edge\Application\msedge.exe"]
        if FileExist(p)
            return p
    return ""
}

Glance_BrowserProcess() {
    exe := Glance_Browser()
    return (exe = "") ? "" : SubStr(exe, InStr(exe, "\", , -1) + 1)
}

Glance_Launch(hidden) {
    global Glance_launching, Glance_launchHidden, Glance_knownWindows, Glance_prevActive, Glance_CalendarUrl
    exe := Glance_Browser()
    if (exe = "") {
        Log("glance", "no browser found (set Glance_BrowserExe at the top of the script)")
        if !hidden
            TrayTip("No Brave / Chrome / Edge found. Set Glance_BrowserExe in glance.ahk.", "glance", 3)
        return false
    }
    Glance_knownWindows := Map()
    for h in WinGetList("ahk_class Chrome_WidgetWin_1")
        Glance_knownWindows[h] := true
    Glance_prevActive := hidden ? WinExist("A") : 0
    Glance_launching := A_TickCount
    Glance_launchHidden := hidden
    Log("glance", (hidden ? "prewarm " : "launch ") . SubStr(exe, InStr(exe, "\", , -1) + 1))
    try {
        Run('"' exe '" --app=' Glance_CalendarUrl)
    } catch as e {
        Log("glance", "run failed: " e.Message)
        Glance_launching := 0
        return false
    }
    SetTimer(Glance_WaitForWindow, 25)
    return true
}

Glance_WaitForWindow() {
    global Glance_launching, Glance_launchHidden, Glance_calWin, Glance_staleWin, Glance_readyAt, Glance_prevActive, Glance_prewarmFailures, Glance_viewDate
    h := Glance_NewBrowserWindow()
    if !h {
        if (A_TickCount - Glance_launching > 15000) {
            SetTimer(Glance_WaitForWindow, 0)
            Glance_launching := 0
            if Glance_launchHidden
                Glance_prewarmFailures += 1
            Log("glance", "window did not appear within 15 s")
        }
        return
    }
    SetTimer(Glance_WaitForWindow, 0)
    elapsed := A_TickCount - Glance_launching
    Glance_calWin := h
    Glance_launching := 0
    Glance_readyAt := A_TickCount
    Glance_prewarmFailures := 0
    Glance_viewDate := FormatTime(, "yyyyMMdd")   ; a new window opens the URL on today
    if Glance_launchHidden {
        WinHide("ahk_id " h)
        Glance_GiveFocusBack()
        Log("glance", "window ready, hidden (" elapsed " ms)")
    } else {
        Glance_Place(h)
        try WinActivate("ahk_id " h)
        Log("glance", "window ready (" elapsed " ms)")
    }
    if Glance_staleWin {
        try WinClose("ahk_id " Glance_staleWin)
        Glance_staleWin := 0
    }
}

Glance_NewBrowserWindow() {
    global Glance_knownWindows
    for h in WinGetList("ahk_class Chrome_WidgetWin_1") {
        if Glance_knownWindows.Has(h)
            continue
        if !DllCall("IsWindowVisible", "ptr", h)
            continue
        if DllCall("GetWindow", "ptr", h, "uint", 4, "ptr")   ; GW_OWNER
            continue
        t := WinGetTitle("ahk_id " h)
        if (t = "" || Glance_IsCalendarTitle(t))
            return h
    }
    return 0
}

Glance_GiveFocusBack() {
    global Glance_prevActive
    if (!Glance_prevActive || !WinExist("ahk_id " Glance_prevActive) || WinActive("ahk_id " Glance_prevActive))
        return
    active := WinExist("A")
    if (!active || WinGetProcessName("ahk_id " active) = Glance_BrowserProcess())
        try WinActivate("ahk_id " Glance_prevActive)
}

Glance_Watch() {
    global Glance_launching, Glance_Prewarm, Glance_goneSince, Glance_lastPrewarm, Glance_prewarmFailures, Glance_browserStartAllowed
    if (Glance_launching || !Glance_Prewarm)
        return
    if Glance_FindCalendarWindow() {
        Glance_goneSince := 0
        return
    }
    now := A_TickCount
    if (now - Glance_startedAt < Glance_PrewarmDelayMs)
        return
    if !Glance_goneSince {
        Glance_goneSince := now
        return
    }
    if (now - Glance_goneSince < 5000 || now - Glance_lastPrewarm < 60000)
        return
    if (Glance_prewarmFailures >= 2) {
        Log("glance", "prewarm failed twice: given up (w still launches)")
        Glance_Prewarm := false
        return
    }
    name := Glance_BrowserProcess()
    if (name = "")
        return
    if (!ProcessExist(name) && !Glance_browserStartAllowed)
        return
    Glance_browserStartAllowed := false
    Glance_lastPrewarm := now, Glance_goneSince := 0
    Glance_Launch(true)
}

Glance_AlignToToday(h) {
    global Glance_viewDate
    today := FormatTime(, "yyyyMMdd")
    if (Glance_viewDate = today)
        return
    if !WinWaitActive("ahk_id " h, , 0.5) {
        Log("glance", "today: window not active, skipped")
        return
    }
    if (GetKeyState("Shift") || GetKeyState("Ctrl") || GetKeyState("Alt") || GetKeyState("LWin") || GetKeyState("RWin")) {
        Log("glance", "today: a modifier is held, skipped")
        return
    }
    Sleep(60)
    if (Glance_viewDate = "" && !Glance_SendKeyTagged(0x58, h))   ; x: custom view
        return
    if !Glance_SendKeyTagged(0x54, h)                      ; t: today
        return
    Log("glance", "today: " . (Glance_viewDate = "" ? "x + t" : "t"))
    Glance_viewDate := today
}

Glance_SendKeyTagged(vk, h) {
    static SIG := 0x4D4D4B42, KEYEVENTF_KEYUP := 2
    if !WinActive("ahk_id " h)
        return false
    sc := DllCall("MapVirtualKey", "UInt", vk, "UInt", 0, "UInt")
    buf := Buffer(80, 0)
    NumPut("UInt", 1, buf, 0)                 ; INPUT_KEYBOARD
    NumPut("UShort", vk, buf, 8)
    NumPut("UShort", sc, buf, 10)
    NumPut("UPtr", SIG, buf, 24)
    NumPut("UInt", 1, buf, 40)
    NumPut("UShort", vk, buf, 48)
    NumPut("UShort", sc, buf, 50)
    NumPut("UInt", KEYEVENTF_KEYUP, buf, 52)
    NumPut("UPtr", SIG, buf, 64)
    n := DllCall("SendInput", "UInt", 2, "Ptr", buf, "Int", 40, "UInt")
    if (n != 2)
        Log("glance", "SendInput sent " n " of 2")
    Sleep(30)
    return n = 2
}

Glance_Place(h) {
    global Glance_WinW, Glance_WinH
    MouseGetPos(&mx, &my)
    MonitorGetWorkArea(Glance_MonitorAt(mx, my), &L, &T, &R, &B)
    w := Min(Glance_WinW, R - L - 16), hgt := Min(Glance_WinH, B - T - 16)
    x := mx + 20, y := my + 20
    if (x + w > R)
        x := mx - w - 20
    if (y + hgt > B)
        y := B - hgt - 8
    x := Max(L, x), y := Max(T, y)
    try {
        if (WinGetMinMax("ahk_id " h) = -1)
            WinRestore("ahk_id " h)
    }
    try WinMove(x, y, w, hgt, "ahk_id " h)
}

Glance_MonitorAt(x, y) {
    loop MonitorGetCount() {
        MonitorGet(A_Index, &L, &T, &R, &B)
        if (x >= L && x < R && y >= T && y < B)
            return A_Index
    }
    return MonitorGetPrimary()
}
