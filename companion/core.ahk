; companion\core.ahk  (AutoHotkey v2)  -- the shared part of mm-companion.ahk
;
; Nothing here runs at load time except the defaults below. The entry script calls
; Core_Init() first, then each enabled module's X_Init(). Modules use:
;   Log(module, text)            one log, mm-companion.log next to the entry script, [module] tag
;   Core_TagKey / Core_TagTap    a key tagged with mousemaster's injected-event signature
;   Core_TagClick                a left click, tagged the same way
;   Core_Plain(keys)             an untagged SendInput ({Blind}: held modifiers untouched);
;                                mousemaster processes it like a typed key
;   Core_MmRunning()             mousemaster.exe is running (checked at most every 2 s)
;   Core_Hotkeys(key, fn)        the key and its Shift/Alt/Ctrl/Alt+Shift variants, RegisterHotKey only
;   Core_SetStatus(module, text) one line in the tray tooltip
; Process-wide defaults set here: title match 2 (substring), hidden windows detected (the
; hidden calendar window must stay reachable), mouse coordinates in screen space.

global Core_LogFile := A_ScriptDir "\mm-companion.log"
global Core_Status := Map()
global Core_HotkeyCount := 0
global Core_MmSeen := false, Core_MmSeenTick := -10000
global Core_OldScripts := ["claude-to-front.ahk", "snipaste-unpin.ahk", "glance.ahk", "ibeam-watch.ahk", "Duplicatefolder2otherpane.ahk"]

Core_Init() {
    SetTitleMatchMode(2)
    DetectHiddenWindows(true)
    CoordMode("Mouse", "Screen")
    OnError(Core_OnError)
    OnExit(Core_OnExit)
    Core_SetupTray()
    Core_CloseStaleCopies()
    Log("core", "start (" A_ScriptName ")")
}

Log(mod, msg) {
    global Core_LogFile
    try {
        if FileExist(Core_LogFile) && FileGetSize(Core_LogFile, "K") > 1024
            FileDelete(Core_LogFile)
        FileAppend(FormatTime(, "yyyy-MM-dd HH:mm:ss") " [" mod "] " msg "`n", Core_LogFile)
    }
}

; An unhandled error is logged instead of shown: a dialog would hold that thread, and with
; every module in one process that is one timer or hotkey stuck. Returning 1 ends the thread
; quietly; timers fire again on their next tick.
Core_OnError(e, mode) {
    Log("core", "ERROR " e.Message " (" e.File ":" e.Line ") " mode)
    return 1
}

Core_OnExit(reason, code) {
    Log("core", "exit (" reason ")")
}

; ---- input ----------------------------------------------------------------------
; dwExtraInfo 0x4D4D4B42 is mousemaster's MOUSEMASTER_INJECTED_EVENT_SIGNATURE: its hook
; passes such events through untouched. INPUT is 40 bytes on x64.
Core_TagKey(vk, sc, up) {
    static SIG := 0x4D4D4B42, KEYEVENTF_KEYUP := 2
    buf := Buffer(40, 0)
    NumPut("UInt", 1, buf, 0)                 ; INPUT_KEYBOARD
    NumPut("UShort", vk, buf, 8)
    NumPut("UShort", sc, buf, 10)
    NumPut("UInt", up ? KEYEVENTF_KEYUP : 0, buf, 12)
    NumPut("UPtr", SIG, buf, 24)
    n := DllCall("SendInput", "UInt", 1, "Ptr", buf, "Int", 40, "UInt")
    if (n != 1)
        Log("core", "SendInput(key " vk ") failed (err " A_LastError ")")
    return n = 1
}

Core_TagTap(vk, sc) {
    return Core_TagKey(vk, sc, false) && Core_TagKey(vk, sc, true)
}

Core_TagClick() {
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
        Log("core", "SendInput(mouse) sent " n " of 2 (err " A_LastError ")")
    return n = 2
}

Core_Plain(keys) {
    SendInput("{Blind}" keys)
}

Core_MmRunning() {
    global Core_MmSeen, Core_MmSeenTick
    if (A_TickCount - Core_MmSeenTick > 2000) {
        Core_MmSeen := ProcessExist("mousemaster.exe") != 0
        Core_MmSeenTick := A_TickCount
    }
    return Core_MmSeen
}

; ---- hotkeys ---------------------------------------------------------------------
; Each variant is one RegisterHotKey: no * wildcard (that needs the keyboard hook). A
; registration that fails makes AutoHotkey fall back to the hook, which is why the old
; scripts must be gone before this runs (Core_CloseStaleCopies waits for them).
Core_Hotkeys(key, fn) {
    global Core_HotkeyCount
    for mods in ["", "+", "!", "^", "!+"] {
        try {
            Hotkey(mods key, fn, "On")
            Core_HotkeyCount++
        } catch as e {
            Log("core", "hotkey " mods key " failed: " e.Message)
        }
    }
}

; One exact key (with its modifiers as written), RegisterHotKey only.
Core_Hotkey(key, fn) {
    global Core_HotkeyCount
    try {
        Hotkey(key, fn, "On")
        Core_HotkeyCount++
    } catch as e {
        Log("core", "hotkey " key " failed: " e.Message)
    }
}

; ---- stale copies ----------------------------------------------------------------
; The old separate scripts, and a copy of this script in another folder (github-export),
; are asked to exit (WM_COMMAND ID_FILE_EXIT), then waited for (3 s at most).
Core_CloseStaleCopies() {
    global Core_OldScripts
    asked := []
    for h in WinGetList("ahk_class AutoHotkey") {
        t := ""
        try t := WinGetTitle("ahk_id " h)
        stale := InStr(t, A_ScriptName) && !InStr(t, A_ScriptFullPath)
        for name in Core_OldScripts
            if InStr(t, name)
                stale := true
        if !stale
            continue
        try PostMessage(0x0111, 65307, 0, , "ahk_id " h)
        asked.Push(h)
        Log("core", "asked to exit: " SubStr(t, InStr(t, "\", , -1) + 1))   ; file name only: no user path in the log
    }
    deadline := A_TickCount + 3000
    while (asked.Length && A_TickCount < deadline) {
        left := []
        for h in asked
            if WinExist("ahk_id " h)
                left.Push(h)
        asked := left
        if asked.Length
            Sleep(50)
    }
    if asked.Length
        Log("core", asked.Length " old script(s) still running: their hotkeys may not be free")
}

; ---- tray ------------------------------------------------------------------------
Core_SetupTray() {
    A_IconTip := "mm-companion"
    A_TrayMenu.Delete()
    A_TrayMenu.Add("Reload", (*) => Reload())
    A_TrayMenu.Add("Open log", (*) => Run(Core_LogFile))
    A_TrayMenu.Add()
    A_TrayMenu.Add("Exit", (*) => ExitApp())
    SetTimer(Core_RefreshTip, 2000)
    ; 2026-10-24: F21 (mousemaster sends it on alt+w in normal-mode) opens this tray menu at the
    ; mouse, so the pointer never has to travel to the tray. Menu.Show() with no position
    ; uses the mouse position.
    ; 2026-10-25: F21 (mousemaster sends it on alt+a) opens Windows' own "show hidden icons" flyout,
    ; every tray app, not only this script: Win+B puts the focus on the notification area, Enter
    ; opens the flyout; in it the arrow keys pick an icon, Enter is a left click and the menu key a
    ; right click. This script's own menu is its icon in there (the green H).
    ; Done here rather than as a mousemaster remapping: the OS still sees the Alt of alt+a (Win+B
    ; arrived as Win+Alt+B, the HDR toggle), and mousemaster skips a -leftalt it believes up.
    Core_Hotkeys("F21", (*) => Core_OpenTrayOverflow())
}

; Every key tagged with mousemaster's signature, so mousemaster lets it through in any mode.
Core_OpenTrayOverflow() {
    Log("core", "tray overflow (F21), alt " (GetKeyState("Alt") ? "down" : "up") ", physical " (GetKeyState("Alt", "P") ? "down" : "up"))
    ; wait for the physical Alt to come up (2 s at most): its auto-repeat puts Alt down again
    t := A_TickCount
    while GetKeyState("Alt", "P") && A_TickCount - t < 2000
        Sleep 15
    Sleep 30
    if GetKeyState("Alt") {
        Core_TagTap(0xA2, 0x1D)                  ; ctrl tap first, so the lone Alt release opens no menu bar
        Core_TagKey(0xA4, 0x38, true)            ; left alt up
        Core_TagKey(0xA5, 0x38, true)            ; right alt up
    }
    Core_TagKey(0x5B, 0x5B, false)               ; left win down
    Core_TagTap(0x42, 0x30)                      ; b
    Core_TagKey(0x5B, 0x5B, true)                ; left win up
    Sleep 150
    Core_TagTap(0x0D, 0x1C)                      ; enter: open the flyout
}

global Core_MenuOpen := false

; Show() blocks until the menu closes, so the hotkey thread hands it to a timer, and a
; second F21 while it is open closes it (Esc) instead of stacking a second menu.
Core_ShowTrayMenu() {
    global Core_MenuOpen
    if Core_MenuOpen {
        Log("core", "tray menu: F21 while open -> close")
        Send("{Esc}")
        return
    }
    SetTimer(Core_ShowTrayMenuNow, -1)
}

Core_ShowTrayMenuNow() {
    global Core_MenuOpen
    Core_MenuOpen := true
    t := A_TickCount
    Log("core", "tray menu at the mouse (F21)")
    try A_TrayMenu.Show()
    Core_MenuOpen := false
    Log("core", "tray menu closed after " (A_TickCount - t) " ms")
}

Core_SetStatus(mod, text) {
    global Core_Status
    Core_Status[mod] := text
}

Core_RefreshTip() {
    global Core_Status
    tip := "mm-companion (mousemaster " (Core_MmRunning() ? "running" : "not running") ")"
    for mod, text in Core_Status
        tip .= "`n" mod ": " text
    A_IconTip := tip
}
