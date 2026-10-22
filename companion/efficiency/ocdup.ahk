; companion\efficiency\ocdup.ahk  (AutoHotkey v2)  -- OneCommander: duplicate a folder into the other pane
;
; Ported into mm-companion on 2026-10-22 from Duplicatefolder2otherpane.ahk (AutoHotkey folder).
; The hotkeys are global, as before (RegisterHotKey; a OneCommander-only condition would need
; the keyboard hook).
;   Alt+1  the current tab's folder opens in a new tab of the other pane
;          (ctrl+l to the address box, ctrl+c, Esc, then alt+f other pane, ctrl+t new tab,
;          ctrl+l, ctrl+v, Enter)
;   Alt+2  the selected folder opens in a new tab of the other pane (shift+ctrl+c copies its path)
;
; Rewritten the same day, after mousemaster.log showed what went wrong: the keys used to be
; sent plain, and mousemaster took them for typed keys. In normal-mode it ate the ctrl of
; shift+ctrl+c, the f of alt+f and ctrl+l, and turned ctrl+t into ctrl+shift+t; even in
; idle-mode the physical Alt of Alt+1 (eaten by mousemaster, so invisible to the OS and to
; AutoHotkey's own modifier handling) made the keys look like Alt+ctrl+l and so on. So
; now every key is sent tagged with mousemaster's injected-event signature (Core_TagKey),
; which its hook passes through untouched in any mode. The Alt that mousemaster put down
; for the hotkey is released first (after a tagged Ctrl tap, so the lone Alt release does
; not open the menu bar). The clipboard is emptied and waited for, since OneCommander's
; copy path fills it a moment later; if ctrl+c caught the selected item instead of the
; address (the address box had no focus yet), its parent folder is used.

OcDup_Init() {
    Core_Hotkey("!1", (*) => OcDup_Tab())
    Core_Hotkey("!2", (*) => OcDup_Selected())
    Log("ocdup", "start")
}

OcDup_Tab() {
    OcDup_Begin()
    OcDup_Chord(true, false, false, 0x4C, 0x26)      ; ctrl+l: the address box
    Sleep 80
    OcDup_Chord(true, false, false, 0x43, 0x2E)      ; ctrl+c
    if !ClipWait(1) {
        Log("ocdup", "alt+1: nothing on the clipboard after 1 s; nothing opened")
        OcDup_Tap(0x1B, 0x01)                        ; Esc
        return
    }
    folder := Trim(A_Clipboard, " `t`r`n")
    if OcDup_ClipboardHasFiles() {
        SplitPath(StrSplit(folder, "`n")[1], , &parent)
        Log("ocdup", "alt+1: the clipboard held the selected item, not the address: using its parent folder")
        folder := parent
    }
    OcDup_Tap(0x1B, 0x01)                            ; Esc: leave the address box
    if (folder = "")
        return
    A_Clipboard := folder
    OcDup_OpenInOtherPane()
}

OcDup_Selected() {
    OcDup_Begin()
    OcDup_Chord(true, true, false, 0x43, 0x2E)       ; shift+ctrl+c: OneCommander's copy path
    if !ClipWait(1) {
        Log("ocdup", "alt+2: nothing on the clipboard after 1 s (no folder selected?)")
        return
    }
    folder := Trim(A_Clipboard, " `t`r`n")
    if OcDup_ClipboardHasFiles()
        folder := StrSplit(folder, "`n")[1]
    if (folder = "")
        return
    A_Clipboard := folder
    OcDup_OpenInOtherPane()
}

; The folder on the clipboard opens in a new tab of the other pane. Short pauses: the pane,
; the new tab and the address box need a moment before they take keys.
OcDup_OpenInOtherPane() {
    OcDup_Chord(false, false, true, 0x46, 0x21)      ; alt+f: the other pane
    Sleep 50
    OcDup_Chord(true, false, false, 0x54, 0x14)      ; ctrl+t: a new tab
    Sleep 100
    OcDup_Chord(true, false, false, 0x4C, 0x26)      ; ctrl+l: the address box
    Sleep 80
    OcDup_Chord(true, false, false, 0x56, 0x2F)      ; ctrl+v
    OcDup_Tap(0x0D, 0x1C)                            ; Enter
}

; Empties the clipboard, and releases the Alt the hotkey came with: mousemaster ate the physical
; Alt and put one down for the OS so that Alt+1 could register, so the OS still sees Alt down.
; A tagged Ctrl tap first keeps the lone Alt release from opening the window's menu bar.
OcDup_Begin() {
    A_Clipboard := ""
    if GetKeyState("Alt") {
        OcDup_Tap(0xA2, 0x1D)                        ; ctrl (mask)
        Core_TagKey(0xA4, 0x38, true)                ; left alt up
    }
}

OcDup_Tap(vk, sc) {
    Core_TagKey(vk, sc, false)
    Core_TagKey(vk, sc, true)
}

OcDup_Chord(ctrl, shift, alt, vk, sc) {
    if ctrl
        Core_TagKey(0xA2, 0x1D, false)
    if shift
        Core_TagKey(0xA0, 0x2A, false)
    if alt
        Core_TagKey(0xA4, 0x38, false)
    OcDup_Tap(vk, sc)
    if alt
        Core_TagKey(0xA4, 0x38, true)
    if shift
        Core_TagKey(0xA0, 0x2A, true)
    if ctrl
        Core_TagKey(0xA2, 0x1D, true)
}

; CF_HDROP (15): a file or folder was copied, not text.
OcDup_ClipboardHasFiles() {
    return DllCall("IsClipboardFormatAvailable", "UInt", 15) != 0
}
