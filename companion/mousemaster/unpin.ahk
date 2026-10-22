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

; Ported into mm-companion on 2026-10-22: functions and state carry the Unpin_ prefix, the
; settings sit in companion\settings.ahk, and what ran at load time is now Unpin_Init().

global Unpin_pins := []            ; window handles, oldest first
global Unpin_closing := Map()      ; hwnd -> tick when an Esc was sent (ignored by Unpin_Scan for a while)

Unpin_Init() {
    global Unpin_pins, Unpin_closing
    Log("unpin", "start (" A_ScriptName " in " SubStr(A_ScriptDir, InStr(A_ScriptDir, "\", , -1) + 1) ")")   ; folder name only: no user path in the log
    SetTimer(Unpin_Scan, Unpin_ScanMs)
    Core_Hotkeys("F14", (*) => Unpin_CloseOldest())
    Core_Hotkeys("F15", (*) => Unpin_CloseAll())
}

Unpin_Scan() {
    global Unpin_pins, Unpin_closing
    keep := []
    for h in Unpin_pins
        if Unpin_IsPin(h)
            keep.Push(h)
    Unpin_pins := keep
    for h, t in Unpin_closing.Clone()
        if (A_TickCount - t > 3000 || !Unpin_IsPin(h))
            Unpin_closing.Delete(h)
    for h in WinGetList("ahk_exe Snipaste.exe") {
        if !Unpin_IsPin(h) || Unpin_closing.Has(h)
            continue
        known := false
        for p in Unpin_pins
            if (p = h) {
                known := true
                break
            }
        if !known {
            Unpin_pins.Push(h)
            Log("unpin", "pin #" Unpin_pins.Length " appeared: " Unpin_Describe(h))
        }
    }
}

Unpin_IsPin(h) {
    if !WinExist("ahk_id " h)
        return false
    if !DllCall("IsWindowVisible", "ptr", h)
        return false
    if !(WinGetExStyle("ahk_id " h) & 0x8)      ; WS_EX_TOPMOST: Unpin_pins float on top
        return false
    if (WinGetTitle("ahk_id " h) != "Paster - Snipaste")   ; the snip overlay, magnifier and toolbar are titled "Snipaste"
        return false
    return true
}

Unpin_Describe(h) {
    try {
        WinGetPos(&x, &y, &w, &hgt, "ahk_id " h)
        return "'" WinGetTitle("ahk_id " h) "' " w "x" hgt " at " x "," y " (" h ")"
    } catch {
        return "(gone)"
    }
}

Unpin_ClosePin(h) {
    global Unpin_closing
    Unpin_closing[h] := A_TickCount
    if WinActive("ahk_id " h) {
        Log("unpin", "close (active, tagged Esc keystroke) " Unpin_Describe(h))
        Unpin_SendTaggedEsc()
    } else {
        Log("unpin", "close (posted Esc) " Unpin_Describe(h))
        Unpin_PostEsc(h)
    }
    SetTimer(() => Unpin_Retry(h), -700)       ; a Unpin_closing pin fades out for a moment; do not Esc it twice
}

Unpin_Retry(h) {
    if !Unpin_IsPin(h)
        return
    Log("unpin", "still there: activating and sending a tagged Esc to " h)
    try WinActivate("ahk_id " h)
    Sleep(60)
    if WinActive("ahk_id " h)
        Unpin_SendTaggedEsc()
    else
        Unpin_PostEsc(h)
}

Unpin_PostEsc(h) {
    try {
        PostMessage(0x0100, 0x1B, 0x00010001, , "ahk_id " h)   ; WM_KEYDOWN VK_ESCAPE, scan 1
        PostMessage(0x0101, 0x1B, 0xC0010001, , "ahk_id " h)   ; WM_KEYUP
    }
}

Unpin_SendTaggedEsc() {
    ; SendInput of VK_ESCAPE down + up, dwExtraInfo = 0x4D4D4B42 (mousemaster's
    ; MOUSEMASTER_INJECTED_EVENT_SIGNATURE), INPUT is 40 bytes on x64.
    ; mousemaster eats the physical Alt of Alt+Z, so the OS normally does not see Alt
    ; down here. If it ever does, release it first (tagged): Alt+Esc is the Windows
    ; window switcher, not an Esc for the pin.
    if GetKeyState("Alt")
        Unpin_SendTaggedKey(0xA4, 0x38, true)       ; VK_LMENU up
    Unpin_SendTaggedKey(0x1B, 0x01, false)          ; Esc down
    Unpin_SendTaggedKey(0x1B, 0x01, true)           ; Esc up
}

Unpin_SendTaggedKey(vk, sc, up) {
    static SIG := 0x4D4D4B42, KEYEVENTF_KEYUP := 2
    buf := Buffer(40, 0)
    NumPut("UInt", 1, buf, 0)                 ; INPUT_KEYBOARD
    NumPut("UShort", vk, buf, 8)
    NumPut("UShort", sc, buf, 10)
    NumPut("UInt", up ? KEYEVENTF_KEYUP : 0, buf, 12)
    NumPut("UPtr", SIG, buf, 24)
    n := DllCall("SendInput", "UInt", 1, "Ptr", buf, "Int", 40, "UInt")
    if (n != 1)
        Log("unpin", "SendInput failed (err " A_LastError ")")
}

Unpin_CloseOldest() {
    global Unpin_pins
    Unpin_Scan()
    Log("unpin", "hotkey " A_ThisHotkey " (OS sees alt=" GetKeyState("Alt") " shift=" GetKeyState("Shift") "), " Unpin_pins.Length " pin(s)")
    if (Unpin_pins.Length = 0)
        return
    Unpin_ClosePin(Unpin_pins.RemoveAt(1))
}

Unpin_CloseAll() {
    global Unpin_pins
    Unpin_Scan()
    if (Unpin_pins.Length = 0) {
        Log("unpin", "F15: no pin on screen")
        return
    }
    while (Unpin_pins.Length > 0) {
        Unpin_ClosePin(Unpin_pins.RemoveAt(1))
        Sleep(120)
    }
}
