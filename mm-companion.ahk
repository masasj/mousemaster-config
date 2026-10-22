; mm-companion.ahk  (AutoHotkey v2)
;
; One resident script for the helpers around mousemaster, in place of the separate ones
; (claude-to-front, snipaste-unpin, glance, ibeam-watch, Duplicatefolder2otherpane). Each lives on as a module
; under companion\; companion\settings.ahk turns them on and off and holds their settings;
; companion\core.ahk is the shared part (log, tagged input, hotkeys, tray).
;
; F keys between mousemaster and the modules (none of them is on the keyboard):
;   F13  mousemaster -> Snipaste   snip (Snipaste's own hotkey, not handled here)
;   F14  mousemaster -> unpin      close the oldest pin (Alt+Z)
;   F15  mousemaster -> unpin      close every pin
;   F16  mousemaster -> glance     show / hide the calendar (w)
;   F17  cursor -> mousemaster     the cursor is the I-beam
;   F18  cursor -> mousemaster     any other standard shape
;   F19  cursor -> mousemaster     an app's own cursor (none of the standard shapes)
;   F20..F24                        free
;
; Started from the Startup folder by install-mm-companion.bat; one green H in the tray
; (hover it for each module's state; right-click: Reload, Open log, Exit).

#Requires AutoHotkey v2.0
#SingleInstance Force
Persistent()

#Include %A_ScriptDir%\companion\settings.ahk
#Include %A_ScriptDir%\companion\core.ahk
#Include %A_ScriptDir%\companion\mousemaster\cursor.ahk
#Include %A_ScriptDir%\companion\mousemaster\unpin.ahk
#Include %A_ScriptDir%\companion\mousemaster\glance.ahk
#Include %A_ScriptDir%\companion\efficiency\front.ahk
#Include %A_ScriptDir%\companion\efficiency\ocdup.ahk

Core_Init()
started := ""
if Enable["cursor"]
    Cursor_Init(), started .= " cursor"
if Enable["unpin"]
    Unpin_Init(), started .= " unpin"
if Enable["glance"]
    Glance_Init(), started .= " glance"
if Enable["front"]
    Front_Init(), started .= " front"
if Enable["ocdup"]
    OcDup_Init(), started .= " ocdup"
Log("core", "modules:" started "; hotkeys registered: " Core_HotkeyCount)
