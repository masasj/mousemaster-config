; ibeam-watch.ahk  (AutoHotkey v2)
;
; Tells mousemaster what shape the mouse cursor has, so the drag animation
; ([33e], the crane) can stay away from text selections, show up for every real
; drag (files, browser tabs, bookmarks, images, window moves), and be drawn in a
; window instead of the cursor image while an app shows its own drag cursor
; (OneCommander's file-name image, the OLE drag cursors) which hides the system
; cursor. mousemaster itself cannot see the cursor shape from its config.
;
;   cursor is the I-beam                     : F17 tap  -> mousemaster.properties: #ibeam
;   cursor is none of the standard shapes    : F19 tap  -> #customcursor
;     (A_Cursor = Unknown: an app's own cursor or drag image, or no cursor)
;   cursor is any other standard shape       : F18 tap  -> ~ibeam ~customcursor
;
; The current state is also re-sent every RESEND_MS so a transition that fell
; into a mode without the F17/F18/F19 macros (a hint mode) is caught up. Nothing
; is sent while mousemaster is not running (the keys would reach the apps).
; {Blind} keeps the user's held modifiers as they are: a plain Send would release
; a held Shift or Ctrl to type the key, which mousemaster would see as leaving
; slow-mode or ending a zoom.
;
; No keyboard or mouse hook: a timer reads A_Cursor (the handle of the cursor on
; screen compared with the system cursors, so it works while mousemaster draws
; its indicator into the cursor image) and SendInput types the one key.
; Events are written to ibeam-watch.log next to this script.

; Ported into mm-companion on 2026-10-22: functions and state carry the Cursor_ prefix, the
; settings sit in companion\settings.ahk, and what ran at load time is now Cursor_Init().

global Cursor_last := ""        ; "" not known yet, "I" I-beam, "C" custom (A_Cursor Unknown), "A" any other standard shape
global Cursor_lastSent := 0
global Cursor_mmSeen := false

Cursor_Init() {
    global Cursor_last, Cursor_lastSent, Cursor_mmSeen
    Log("cursor", "start (" A_ScriptName ")")
    SetTimer(Cursor_Poll, Cursor_PollMs)
}

Cursor_Poll() {
    global Cursor_last, Cursor_lastSent, Cursor_mmSeen
    c := A_Cursor
    cur := (c = "IBeam") ? "I" : (c = "Unknown") ? "C" : "A"
    changed := (cur != Cursor_last)
    if !changed && (A_TickCount - Cursor_lastSent < Cursor_ResendMs)
        return
    running := ProcessExist("mousemaster.exe") != 0
    if (running != Cursor_mmSeen) {
        Log("cursor", running ? "mousemaster is running: sending F17/F18" : "mousemaster not running: sending nothing")
        Cursor_mmSeen := running
    }
    if !running {
        Cursor_last := cur
        return
    }
    SendInput(cur = "I" ? "{Blind}{F17}" : cur = "C" ? "{Blind}{F19}" : "{Blind}{F18}")
    if changed
        Log("cursor", cur = "I" ? "I-beam -> F17" : cur = "C" ? "custom cursor -> F19" : "other -> F18")
    Cursor_last := cur
    Cursor_lastSent := A_TickCount
}
