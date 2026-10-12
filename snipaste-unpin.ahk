; snipaste-unpin.ahk  (AutoHotkey v2)
;
; Closes Snipaste pins ("pasted" images, title "Paster - Snipaste") oldest-first,
; from any app.
;   F14 : close the oldest pin still on screen   (mousemaster sends it on Alt+Z
;         in normal-mode: mousemaster.properties [31b])
;   F15 : close every pin, oldest first          (not bound in mousemaster yet)
;
; Why a script: Snipaste closes a pin on Esc only while that pin is the active
; window. As soon as you touch another app, Esc goes to that app. There is no
; Snipaste hotkey for "close the oldest / close all", and Ctrl+A is not a
; select-all for pins (checked 2026-10-12).
;
; How: every SCAN_MS the script lists the visible topmost "Paster - Snipaste"
; windows of Snipaste.exe and remembers each one the first time it is seen, so
; the list is in creation order. Closing means an Esc for that one window:
;   - pin not active: WM_KEYDOWN/WM_KEYUP VK_ESCAPE posted straight to its handle
;     (no focus change, nothing enters the input stream). Measured 2026-10-12:
;     this works; WM_CLOSE does nothing (Snipaste ignores it).
;   - pin active: a posted Esc is ignored (measured), so a real Esc keystroke is
;     sent with SendInput, tagged with mousemaster's injected-event signature
;     (dwExtraInfo 0x4D4D4B42) so mousemaster lets it through untouched. It goes
;     to the active window, which is the pin.
;   - still there after 700 ms: activate the pin and send the tagged Esc.
; Snipaste treats Esc as "close": the pin goes to its history (same as the
; right-click menu's close; "destroy" is not used).
;
; No keyboard or mouse hook is installed: F14/F15 go through RegisterHotKey, and
; the only injected input is the tagged Esc above (mousemaster-safe, same rule
; as claude-to-front.ahk). Events are written to snipaste-unpin.log next to
; this script.

#Requires AutoHotkey v2.0
#SingleInstance Force
Persistent()

SCAN_MS  := 500
LogFile  := A_ScriptDir "\snipaste-unpin.log"
global pins := []            ; window handles, oldest first
global closing := Map()      ; hwnd -> tick when an Esc was sent (ignored by Scan for a while)

CloseStaleCopies()
Log("start (" A_ScriptName " in " SubStr(A_ScriptDir, InStr(A_ScriptDir, "\", , -1) + 1) ")")   ; folder name only: no user path in the log
SetTimer(Scan, SCAN_MS)

Scan() {
    global pins, closing
    keep := []
    for h in pins
        if IsPin(h)
            keep.Push(h)
    pins := keep
    for h, t in closing.Clone()
        if (A_TickCount - t > 3000 || !IsPin(h))
            closing.Delete(h)
    for h in WinGetList("ahk_exe Snipaste.exe") {
        if !IsPin(h) || closing.Has(h)
            continue
        known := false
        for p in pins
            if (p = h) {
                known := true
                break
            }
        if !known {
            pins.Push(h)
            Log("pin #" pins.Length " appeared: " Describe(h))
        }
    }
}

IsPin(h) {
    if !WinExist("ahk_id " h)
        return false
    if !DllCall("IsWindowVisible", "ptr", h)
        return false
    if !(WinGetExStyle("ahk_id " h) & 0x8)      ; WS_EX_TOPMOST: pins float on top
        return false
    if (WinGetTitle("ahk_id " h) != "Paster - Snipaste")   ; the snip overlay, magnifier and toolbar are titled "Snipaste"
        return false
    return true
}

Describe(h) {
    try {
        WinGetPos(&x, &y, &w, &hgt, "ahk_id " h)
        return "'" WinGetTitle("ahk_id " h) "' " w "x" hgt " at " x "," y " (" h ")"
    } catch {
        return "(gone)"
    }
}

ClosePin(h) {
    global closing
    closing[h] := A_TickCount
    if WinActive("ahk_id " h) {
        Log("close (active, tagged Esc keystroke) " Describe(h))
        SendTaggedEsc()
    } else {
        Log("close (posted Esc) " Describe(h))
        PostEsc(h)
    }
    SetTimer(() => Retry(h), -700)       ; a closing pin fades out for a moment; do not Esc it twice
}

Retry(h) {
    if !IsPin(h)
        return
    Log("still there: activating and sending a tagged Esc to " h)
    try WinActivate("ahk_id " h)
    Sleep(60)
    if WinActive("ahk_id " h)
        SendTaggedEsc()
    else
        PostEsc(h)
}

PostEsc(h) {
    try {
        PostMessage(0x0100, 0x1B, 0x00010001, , "ahk_id " h)   ; WM_KEYDOWN VK_ESCAPE, scan 1
        PostMessage(0x0101, 0x1B, 0xC0010001, , "ahk_id " h)   ; WM_KEYUP
    }
}

SendTaggedEsc() {
    ; SendInput of VK_ESCAPE down + up, dwExtraInfo = 0x4D4D4B42 (mousemaster's
    ; MOUSEMASTER_INJECTED_EVENT_SIGNATURE), INPUT is 40 bytes on x64.
    ; mousemaster eats the physical Alt of Alt+Z, so the OS normally does not see Alt
    ; down here. If it ever does, release it first (tagged): Alt+Esc is the Windows
    ; window switcher, not an Esc for the pin.
    if GetKeyState("Alt")
        SendTaggedKey(0xA4, 0x38, true)       ; VK_LMENU up
    SendTaggedKey(0x1B, 0x01, false)          ; Esc down
    SendTaggedKey(0x1B, 0x01, true)           ; Esc up
}

SendTaggedKey(vk, sc, up) {
    static SIG := 0x4D4D4B42, KEYEVENTF_KEYUP := 2
    buf := Buffer(40, 0)
    NumPut("UInt", 1, buf, 0)                 ; INPUT_KEYBOARD
    NumPut("UShort", vk, buf, 8)
    NumPut("UShort", sc, buf, 10)
    NumPut("UInt", up ? KEYEVENTF_KEYUP : 0, buf, 12)
    NumPut("UPtr", SIG, buf, 24)
    n := DllCall("SendInput", "UInt", 1, "Ptr", buf, "Int", 40, "UInt")
    if (n != 1)
        Log("SendInput failed (err " A_LastError ")")
}

CloseOldest() {
    global pins
    Scan()
    Log("hotkey " A_ThisHotkey " (OS sees alt=" GetKeyState("Alt") " shift=" GetKeyState("Shift") "), " pins.Length " pin(s)")
    if (pins.Length = 0)
        return
    ClosePin(pins.RemoveAt(1))
}

CloseAll() {
    global pins
    Scan()
    if (pins.Length = 0) {
        Log("F15: no pin on screen")
        return
    }
    while (pins.Length > 0) {
        ClosePin(pins.RemoveAt(1))
        Sleep(120)
    }
}

CloseStaleCopies() {
    ; Another copy of this script (e.g. one started from github-export\) would
    ; answer F14 too. Ask it to exit. AutoHotkey's hidden main window is titled
    ; "<script path> - AutoHotkey v2...".
    prev := A_DetectHiddenWindows
    DetectHiddenWindows(true)
    for h in WinGetList("ahk_class AutoHotkey") {
        t := WinGetTitle("ahk_id " h)
        if InStr(t, "snipaste-unpin.ahk") && !InStr(t, A_ScriptFullPath) {
            try PostMessage(0x0111, 65307, 0, , "ahk_id " h)   ; WM_COMMAND ID_FILE_EXIT: the other script exits
            Log("asked a stale copy of this script (another folder) to exit")
        }
    }
    DetectHiddenWindows(prev)
}

; mousemaster sends F14 on Alt+Z; whether the OS still sees Alt (or Shift) held at
; that moment depends on the mode, so every modifier variant is registered. Each
; line is one RegisterHotKey: no wildcard (*), which would need the keyboard hook.
F14::CloseOldest()
+F14::CloseOldest()
!F14::CloseOldest()
!+F14::CloseOldest()
F15::CloseAll()
+F15::CloseAll()
!F15::CloseAll()
!+F15::CloseAll()

Log(msg) {
    global LogFile
    try {
        if FileExist(LogFile) && FileGetSize(LogFile, "K") > 256
            FileDelete(LogFile)
        FileAppend(FormatTime(, "yyyy-MM-dd HH:mm:ss") " " msg "`n", LogFile)
    }
}
