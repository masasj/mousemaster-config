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

#Requires AutoHotkey v2.0
#SingleInstance Force
Persistent()
SetTitleMatchMode(2)
DetectHiddenWindows(true)      ; the hidden calendar window must stay reachable by hwnd
CoordMode("Mouse", "Screen")   ; v2 default is Client (relative to the active window): the window landed in the wrong place

global LogFile := A_ScriptDir "\glance.log"
global CalendarUrl := "https://calendar.google.com/calendar/u/0/r/customday"
global WinW := 880, WinH := 660
global BrowserExe := ""        ; leave empty to auto-detect; or e.g. "C:\Program Files\BraveSoftware\Brave-Browser\Application\brave.exe"
; Prewarm: keep the calendar window ready (hidden) while the browser runs, so w is instant.
;   PrewarmDelayMs after this script starts (sign-in), the browser is started for it if it
;   is not running; later (browser quit by hand), only a running browser gets the window.
;   Consequence: the hidden window keeps the browser process alive after its last visible
;   window is closed (quit it from its menu, or set Prewarm := false: w then launches, 1-2 s).
global Prewarm := true
global PrewarmDelayMs := 45000

global calWin := 0             ; hwnd of the calendar window (0 = none known)
global launching := 0          ; tick count of the launch in progress (0 = none)
global launchHidden := false   ; the launch in progress is a prewarm: hide the window as soon as it appears
global knownWindows := Map()   ; browser windows that existed before the launch
global prevActive := 0         ; window that was active before a prewarm launch (focus is given back)
global staleWin := 0           ; a window to close once the new one is up (its page never loaded)
global readyAt := 0            ; tick count when the current window appeared
global goneSince := 0          ; tick count since the window has been missing
global lastPrewarm := 0
global prewarmFailures := 0
global browserStartAllowed := true
global startedAt := A_TickCount
global viewDate := ""          ; day (yyyyMMdd) the view was last set to today ("" = unknown: adopted window)

CloseStaleCopies()
Log("start (" A_ScriptName " in " SubStr(A_ScriptDir, InStr(A_ScriptDir, "\", , -1) + 1) ")")   ; folder name only: no user path in the log
if FindCalendarWindow()
    Log("adopted an existing calendar window")
SetTimer(Watch, 3000)

; mousemaster sends F16 on w in normal-mode. Whether the OS still sees a modifier
; held at that moment depends on the mode, so the plain variants are all registered.
; Each line is one RegisterHotKey: no wildcard (*), which would need the keyboard hook.
F16::Toggle()
+F16::Toggle()
!F16::Toggle()
^F16::Toggle()

Toggle() {
    global launching, launchHidden, staleWin, calWin, readyAt
    h := FindCalendarWindow()
    if !h {
        if launching {
            if launchHidden {
                launchHidden := false     ; the prewarm in progress is shown as soon as it appears
                Log("toggle while prewarming: shown when ready")
            } else
                Log("toggle while launching: ignored")
            return
        }
        Launch(false)
        return
    }
    if (DllCall("IsWindowVisible", "ptr", h) && !DllCall("IsIconic", "ptr", h)) {
        WinHide("ahk_id " h)
        Log("hide")
        return
    }
    ; A title that is still the address 15 s after the window appeared: the page never
    ; loaded (e.g. prewarmed at sign-in before the network was up). A new window
    ; replaces it; the old one is closed once the new one is up, so the browser stays.
    t := ""
    try t := WinGetTitle("ahk_id " h)
    if (A_TickCount - readyAt > 15000 && RegExMatch(t, "i)^calendar\.google\.com")) {
        Log("page did not load (title is still the address): new window")
        staleWin := h, calWin := 0
        Launch(false)
        return
    }
    Place(h)
    WinShow("ahk_id " h)
    try WinActivate("ahk_id " h)
    Log("show")
    AlignToToday(h)
}

; The known window by hwnd, else (script restarted) by title. The app window's title is
; the page title alone ("Google Calendar - October 2026", "Google <katakana calendar>
; - 2026...", or the address while loading); a normal browser window with a calendar
; tab ends with " - Google Chrome" / " - Brave" / " - Microsoft Edge" and is skipped.
FindCalendarWindow() {
    global calWin
    if (calWin && WinExist("ahk_id " calWin) && WinGetClass("ahk_id " calWin) = "Chrome_WidgetWin_1")
        return calWin
    calWin := 0
    for h in WinGetList("ahk_class Chrome_WidgetWin_1") {
        if IsCalendarTitle(WinGetTitle("ahk_id " h)) {
            calWin := h
            break
        }
    }
    return calWin
}

IsCalendarTitle(t) {
    static jp := "Google " Chr(0x30AB) Chr(0x30EC) Chr(0x30F3) Chr(0x30C0) Chr(0x30FC)
    if (t = "")
        return false
    if !(InStr(t, "Google Calendar") || InStr(t, jp) || InStr(t, "calendar.google.com"))
        return false
    return !RegExMatch(t, "i)- (Google Chrome|Brave|Microsoft\x{200B}? Edge|Chromium)$")
}

Browser() {
    global BrowserExe
    if (BrowserExe != "" && FileExist(BrowserExe))
        return BrowserExe
    lad := EnvGet("LOCALAPPDATA")
    pf := A_ProgramFiles
    pf86 := EnvGet("ProgramFiles(x86)")
    for p in [pf "\BraveSoftware\Brave-Browser\Application\brave.exe",
              lad "\BraveSoftware\Brave-Browser\Application\brave.exe",
              pf "\Google\Chrome\Application\chrome.exe",
              lad "\Google\Chrome\Application\chrome.exe",
              pf86 "\Microsoft\Edge\Application\msedge.exe",
              pf "\Microsoft\Edge\Application\msedge.exe"]
        if FileExist(p)
            return p
    return ""
}

BrowserProcess() {
    exe := Browser()
    return (exe = "") ? "" : SubStr(exe, InStr(exe, "\", , -1) + 1)
}

; hidden = true: prewarm (the window is hidden the moment it appears, focus goes back).
Launch(hidden) {
    global launching, launchHidden, knownWindows, prevActive, CalendarUrl
    exe := Browser()
    if (exe = "") {
        Log("no browser found (set BrowserExe at the top of the script)")
        if !hidden
            TrayTip("No Brave / Chrome / Edge found. Set BrowserExe in glance.ahk.", "glance", 3)
        return false
    }
    knownWindows := Map()
    for h in WinGetList("ahk_class Chrome_WidgetWin_1")
        knownWindows[h] := true
    prevActive := hidden ? WinExist("A") : 0
    launching := A_TickCount
    launchHidden := hidden
    Log((hidden ? "prewarm " : "launch ") . SubStr(exe, InStr(exe, "\", , -1) + 1))
    try {
        Run('"' exe '" --app=' CalendarUrl)
    } catch as e {
        Log("run failed: " e.Message)
        launching := 0
        return false
    }
    SetTimer(WaitForWindow, 25)
    return true
}

WaitForWindow() {
    global launching, launchHidden, calWin, staleWin, readyAt, prevActive, prewarmFailures, viewDate
    h := NewBrowserWindow()
    if !h {
        if (A_TickCount - launching > 15000) {
            SetTimer(WaitForWindow, 0)
            launching := 0
            if launchHidden
                prewarmFailures += 1
            Log("window did not appear within 15 s")
        }
        return
    }
    SetTimer(WaitForWindow, 0)
    elapsed := A_TickCount - launching
    calWin := h
    launching := 0
    readyAt := A_TickCount
    prewarmFailures := 0
    viewDate := FormatTime(, "yyyyMMdd")   ; a new window opens the URL on today
    if launchHidden {
        WinHide("ahk_id " h)
        GiveFocusBack()
        Log("window ready, hidden (" elapsed " ms)")
    } else {
        Place(h)
        try WinActivate("ahk_id " h)
        Log("window ready (" elapsed " ms)")
    }
    if staleWin {
        try WinClose("ahk_id " staleWin)
        staleWin := 0
    }
}

; The first browser top-level window that did not exist before the launch (visible,
; not owned by another window: menus and tooltips are). Its title is the address at
; first ("calendar.google.com"), the page title later, briefly empty before that.
NewBrowserWindow() {
    global knownWindows
    for h in WinGetList("ahk_class Chrome_WidgetWin_1") {
        if knownWindows.Has(h)
            continue
        if !DllCall("IsWindowVisible", "ptr", h)
            continue
        if DllCall("GetWindow", "ptr", h, "uint", 4, "ptr")   ; GW_OWNER
            continue
        t := WinGetTitle("ahk_id " h)
        if (t = "" || IsCalendarTitle(t))
            return h
    }
    return 0
}

; After a prewarm, the new window had the focus for a moment. If it did not fall back
; to the window that had it before (or fell to another browser window), give it back.
GiveFocusBack() {
    global prevActive
    if (!prevActive || !WinExist("ahk_id " prevActive) || WinActive("ahk_id " prevActive))
        return
    active := WinExist("A")
    if (!active || WinGetProcessName("ahk_id " active) = BrowserProcess())
        try WinActivate("ahk_id " prevActive)
}

; Prewarm: when no calendar window exists, launch one hidden. The decision waits a few
; seconds (a browser whose last window was just closed is quitting: it is left alone
; unless it is still running by then) and never repeats within a minute.
Watch() {
    global launching, Prewarm, goneSince, lastPrewarm, prewarmFailures, browserStartAllowed
    if (launching || !Prewarm)
        return
    if FindCalendarWindow() {
        goneSince := 0
        return
    }
    now := A_TickCount
    if (now - startedAt < PrewarmDelayMs)
        return
    if !goneSince {
        goneSince := now
        return
    }
    if (now - goneSince < 5000 || now - lastPrewarm < 60000)
        return
    if (prewarmFailures >= 2) {
        Log("prewarm failed twice: given up (w still launches)")
        Prewarm := false
        return
    }
    name := BrowserProcess()
    if (name = "")
        return
    if (!ProcessExist(name) && !browserStartAllowed)
        return
    browserStartAllowed := false
    lastPrewarm := now, goneSince := 0
    Launch(true)
}

; The first show of a day: Google Calendar's own t (today), so the 7 days start today.
; A window of unknown view (adopted after a restart) first gets x (custom view). The
; keys go only to the calendar window, only while it is active and no modifier is held,
; and carry mousemaster's injected-event signature (mousemaster passes them through).
AlignToToday(h) {
    global viewDate
    today := FormatTime(, "yyyyMMdd")
    if (viewDate = today)
        return
    if !WinWaitActive("ahk_id " h, , 0.5) {
        Log("today: window not active, skipped")
        return
    }
    if (GetKeyState("Shift") || GetKeyState("Ctrl") || GetKeyState("Alt") || GetKeyState("LWin") || GetKeyState("RWin")) {
        Log("today: a modifier is held, skipped")
        return
    }
    Sleep(60)
    if (viewDate = "" && !SendKeyTagged(0x58, h))   ; x: custom view
        return
    if !SendKeyTagged(0x54, h)                      ; t: today
        return
    Log("today: " . (viewDate = "" ? "x + t" : "t"))
    viewDate := today
}

; One key tap (down + up) to the active window h, tagged with dwExtraInfo 0x4D4D4B42
; (mousemaster's MOUSEMASTER_INJECTED_EVENT_SIGNATURE). INPUT is 40 bytes on x64.
SendKeyTagged(vk, h) {
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
        Log("SendInput sent " n " of 2")
    Sleep(30)
    return n = 2
}

; Next to the mouse, on the monitor the mouse is on, inside its work area; moved while
; still hidden, so it appears in place.
Place(h) {
    global WinW, WinH
    MouseGetPos(&mx, &my)
    MonitorGetWorkArea(MonitorAt(mx, my), &L, &T, &R, &B)
    w := Min(WinW, R - L - 16), hgt := Min(WinH, B - T - 16)
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

MonitorAt(x, y) {
    loop MonitorGetCount() {
        MonitorGet(A_Index, &L, &T, &R, &B)
        if (x >= L && x < R && y >= T && y < B)
            return A_Index
    }
    return MonitorGetPrimary()
}

CloseStaleCopies() {
    ; Another copy of this script (e.g. one started from github-export\) would
    ; answer F16 too. Ask it to exit.
    for h in WinGetList("ahk_class AutoHotkey") {
        t := WinGetTitle("ahk_id " h)
        if InStr(t, "glance.ahk") && !InStr(t, A_ScriptFullPath) {
            try PostMessage(0x0111, 65307, 0, , "ahk_id " h)   ; WM_COMMAND ID_FILE_EXIT
            Log("asked a stale copy of this script (another folder) to exit")
        }
    }
}

Log(msg) {
    global LogFile
    try FileAppend(FormatTime(, "yyyy-MM-dd HH:mm:ss") " " msg "`n", LogFile, "UTF-8")
}
