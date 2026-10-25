; companion\settings.ahk  (AutoHotkey v2)  -- the part of mm-companion you edit
; A module that is off is never initialised: no timer, no hotkey, nothing in the log.

global Enable := Map("cursor", true, "unpin", true, "glance", true, "front", true, "ocdup", true)

; core: F21 opens Windows' hidden-icons flyout (mousemaster sends it on alt+a)
; cursor (mousemaster\cursor.ahk): the cursor shape -> F17 I-beam / F19 an app's own cursor / F20 crosshair / F18 other
global Cursor_PollMs := 16          ; how often the cursor is read
global Cursor_ResendMs := 3000      ; the current state is re-sent this often

; unpin (mousemaster\unpin.ahk): F14 closes the oldest Snipaste pin, F15 all of them
global Unpin_ScanMs := 500

; glance (mousemaster\glance.ahk): F16 shows / hides Google Calendar next to the mouse
global Glance_CalendarUrl := "https://calendar.google.com/calendar/u/0/r/customday"
global Glance_WinW := 880, Glance_WinH := 660
global Glance_BrowserExe := ""      ; empty: Brave, then Chrome, then Edge; or a full path to the browser exe
global Glance_Prewarm := true       ; launch the calendar window hidden ahead of time
global Glance_PrewarmDelayMs := 45000

; ocdup (efficiency\ocdup.ahk): Alt+1 / Alt+2 duplicate a folder into OneCommander's other pane (no settings)

; front (efficiency\front.ahk): a Claude window whose taskbar button flashes after a click is activated
global Front_IdleMs := 800          ; keyboard or mouse input within this many ms counts as "the click"
global Front_ToastMs := 2500
global Front_RequireToast := false
global Front_RetryMs := 4000
