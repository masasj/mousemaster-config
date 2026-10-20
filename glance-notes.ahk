; glance-notes.ahk  (AutoHotkey v2)  -- the earlier clock + notes window, optional. glance.ahk now shows Google Calendar itself.
;
; A small always-on-top "glance" window next to the mouse: a digital clock with the
; date, this month's calendar, and the day's entries. Mouse first: click a day,
; type, Enter. Nothing else has to be open.
;   F16 : show / hide   (mousemaster sends it on w in normal-mode: mousemaster.properties [34])
;   Esc : hide           (while the window is active)
;   <  > : previous / next month, click the month name to come back to today
;   click a day     : select it (its entries are listed below, the edit box gets the focus)
;   type + Enter    : add an entry to the selected day (the + button does the same)
;                     "14:00 dentist" makes a one-hour event at 14:00, "14:00-15:30 dentist" sets the end,
;                     anything else is an all-day entry
;   double-click an entry : delete it
;
; Two backends, picked at start:
;   Google Calendar (primary calendar) when glance-gcal-token.json exists next to this
;     script: glance-gcal.ps1 lists the month (in the background, the window shows the
;     last cached listing at once), adds and deletes. Setup: GLANCE-GCAL-SETUP.md.
;   otherwise a local file, glance-events.txt, one line per entry: YYYY-MM-DD<TAB>title
;
; Why a script: mousemaster's indicator layers can show text, but only text written
; in the configuration. Nothing in it knows the time, the date or a calendar, so a
; glance has to come from outside, and mousemaster can only send a key. Same recipe
; as snipaste-unpin.ahk: a RegisterHotKey on an F key nobody uses, no keyboard or
; mouse hook, nothing injected.
; Events are written to glance.log next to this script (no user paths in it).

#Requires AutoHotkey v2.0
#SingleInstance Force
Persistent()

global DataFile := A_ScriptDir "\glance-events.txt"
global LogFile := A_ScriptDir "\glance.log"
global GcalScript := A_ScriptDir "\glance-gcal.ps1"
global GcalToken := A_ScriptDir "\glance-gcal-token.json"
global GcalCache := A_ScriptDir "\glance-gcal-cache.txt"
global gcal := FileExist(GcalToken) && FileExist(GcalScript)   ; Google mode
global events := Map()               ; "YYYY-MM-DD" -> Array of {time, title, id}
global viewY := Integer(A_YYYY), viewM := Integer(A_MM)
global selKey := FormatTime(, "yyyy-MM-dd")
global shown := false
global g := 0, timeCtl := 0, dateCtl := 0, monthCtl := 0, selCtl := 0, listCtl := 0, editCtl := 0, statusCtl := 0
global cellCtl := []
global lastDay := FormatTime(, "yyyy-MM-dd")
global fetchPid := 0, fetchedYM := ""

if gcal
    LoadCache()
else
    LoadEvents()
BuildGui()
CloseStaleCopies()
Log("start (" A_ScriptName " in " SubStr(A_ScriptDir, InStr(A_ScriptDir, "\", , -1) + 1) ", " (gcal ? "google" : "local") ")")   ; folder name only: no user path in the log

; mousemaster sends F16 on w in normal-mode (c is screen-selection-mode). Whether the
; OS still sees a modifier held at that moment depends on the mode, so the plain
; variants are all registered. Each line is one RegisterHotKey: no wildcard (*),
; which would need the keyboard hook.
F16::Toggle()
+F16::Toggle()
!F16::Toggle()
^F16::Toggle()

Toggle() {
    global shown
    if shown
        Hide()
    else
        Show()
}

Show() {
    global g, shown
    MouseGetPos(&mx, &my)
    MonitorGetWorkArea(MonitorFromPoint(mx, my), &L, &T, &R, &B)
    RenderMonth()
    Tick()
    g.Show("Hide AutoSize")          ; lay the controls out to learn the size
    g.GetPos(, , &w, &h)
    x := mx + 24, y := my + 24
    if (x + w > R)
        x := mx - w - 24
    if (y + h > B)
        y := B - h - 8
    x := Max(L, x), y := Max(T, y)
    ; NoActivate: a glance does not take the focus away from what you were doing, and
    ; mousemaster stays in normal-mode (w again hides it). Clicking a day activates
    ; the window, which switches mousemaster to glance-mode (keys pass through) so
    ; an entry can be typed. Esc hides it and the focus goes back.
    g.Show("x" x " y" y " NoActivate")
    shown := true
    SetTimer(Tick, 1000)
    if gcal
        FetchMonth()
    Log("show")
}

Hide() {
    global g, shown
    SetTimer(Tick, 0)
    g.Hide()
    shown := false
    Log("hide")
}

MonitorFromPoint(x, y) {
    loop MonitorGetCount() {
        MonitorGet(A_Index, &L, &T, &R, &B)
        if (x >= L && x < R && y >= T && y < B)
            return A_Index
    }
    return MonitorGetPrimary()
}

BuildGui() {
    global g, timeCtl, dateCtl, monthCtl, selCtl, listCtl, editCtl, statusCtl, cellCtl
    g := Gui("+AlwaysOnTop -Caption +ToolWindow +Border", "glance")
    g.BackColor := "1E2228"
    g.MarginX := 14, g.MarginY := 10
    g.SetFont("s26 cFFFFFF w600", "Segoe UI")
    timeCtl := g.AddText("w312 Center", "00:00:00")
    g.SetFont("s10 cB0B8C0 w400", "Segoe UI")
    dateCtl := g.AddText("xm w312 Center", "")
    g.SetFont("s11 cFFFFFF w600", "Segoe UI")
    prevBtn := g.AddText("xm y+8 w28 h24 Center 0x200 Background2B2F36", "<")
    prevBtn.OnEvent("Click", (*) => ShiftMonth(-1))
    monthCtl := g.AddText("x+4 w248 h24 Center 0x200", "")
    monthCtl.OnEvent("Click", (*) => GoToday())
    nextBtn := g.AddText("x+4 w28 h24 Center 0x200 Background2B2F36", ">")
    nextBtn.OnEvent("Click", (*) => ShiftMonth(1))
    g.SetFont("s9 c8A94A0 w400", "Segoe UI")
    for i, d in ["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"]
        g.AddText((i = 1 ? "xm y+6 " : "x+2 ") "w43 Center", d)
    g.SetFont("s10 cE6EDF3 w400", "Segoe UI")
    loop 42 {
        i := A_Index
        opt := (Mod(i - 1, 7) = 0 ? "xm y+2 " : "x+2 ") "w43 h27 Center 0x200 Background2B2F36"   ; 0x200 = SS_CENTERIMAGE (vertical centering)
        t := g.AddText(opt, "")
        t.OnEvent("Click", CellClick.Bind(i))
        t.OnEvent("DoubleClick", CellClick.Bind(i))
        cellCtl.Push(t)
    }
    g.SetFont("s9 c8A94A0 w400", "Segoe UI")
    selCtl := g.AddText("xm y+8 w312", "")
    g.SetFont("s10 cE6EDF3 w400", "Segoe UI")
    listCtl := g.AddListBox("xm y+2 w312 r4 Background2B2F36", [])
    listCtl.OnEvent("DoubleClick", DeleteEntry)
    editCtl := g.AddEdit("xm y+4 w268 Background2B2F36", "")
    addBtn := g.AddButton("x+4 w40 Default", "+")
    addBtn.OnEvent("Click", AddEntry)
    g.SetFont("s8 c6E7A86 w400", "Segoe UI")
    g.AddText("xm y+4 w312", "click a day, type, Enter = add (14:00 title = timed)   /   double-click = delete   /   Esc = hide")
    statusCtl := g.AddText("xm y+2 w312", gcal ? "Google Calendar" : "local notes (glance-events.txt)")
    g.OnEvent("Escape", (*) => Hide())
    g.OnEvent("Close", (*) => Hide())
}

Tick() {
    global timeCtl, dateCtl, lastDay, selKey
    timeCtl.Text := FormatTime(, "HH:mm:ss")
    dateCtl.Text := FormatTime(, "yyyy-MM-dd dddd")
    today := FormatTime(, "yyyy-MM-dd")
    if (today != lastDay) {            ; midnight: today moves, the selection follows if it was on the old day
        if (selKey = lastDay)
            selKey := today
        lastDay := today
        RenderMonth()
    }
}

DaysIn(y, m) {
    first := Format("{:04}{:02}01", y, m)
    next := m = 12 ? Format("{:04}0101", y + 1) : Format("{:04}{:02}01", y, m + 1)
    return DateDiff(next, first, "Days")
}

ShiftMonth(delta) {
    global viewY, viewM
    viewM += delta
    if (viewM < 1) {
        viewM := 12
        viewY -= 1
    } else if (viewM > 12) {
        viewM := 1
        viewY += 1
    }
    RenderMonth()
    if gcal
        FetchMonth()
}

GoToday() {
    global viewY, viewM, selKey
    viewY := Integer(A_YYYY), viewM := Integer(A_MM)
    selKey := FormatTime(, "yyyy-MM-dd")
    RenderMonth()
    if gcal
        FetchMonth()
}

RenderMonth() {
    global viewY, viewM, cellCtl, selKey, events, monthCtl
    first := Format("{:04}{:02}01", viewY, viewM)
    dow := Integer(FormatTime(first, "WDay"))      ; 1 = Sunday
    n := DaysIn(viewY, viewM)
    monthCtl.Text := Format("{:04}  /  {:02}", viewY, viewM)
    today := FormatTime(, "yyyy-MM-dd")
    loop 42 {
        i := A_Index
        d := i - (dow - 1)
        c := cellCtl[i]
        if (d < 1 || d > n) {
            c.Text := ""
            c.Opt("Background1E2228")
            c.SetFont("cE6EDF3 w400")
            c.Redraw()
            continue
        }
        key := Format("{:04}-{:02}-{:02}", viewY, viewM, d)
        cnt := events.Has(key) ? events[key].Length : 0
        c.Text := d . (cnt ? " *" : "")
        bg := key = selKey ? "5B9DFF" : (key = today ? "3A4452" : (cnt ? "35454B" : "2B2F36"))
        c.Opt("Background" bg)
        c.SetFont(key = today ? "cFFFFFF w700" : "cE6EDF3 w400")
        c.Redraw()
    }
    RenderList()
}

RenderList() {
    global selCtl, listCtl, selKey, events
    selCtl.Text := selKey "  " FormatTime(StrReplace(selKey, "-"), "dddd") "   (" (events.Has(selKey) ? events[selKey].Length : 0) ")"
    listCtl.Delete()
    if events.Has(selKey)
        for e in events[selKey]
            listCtl.Add([(e.time != "" ? e.time "  " : "") e.title])
}

CellClick(i, ctl, info) {
    global viewY, viewM, selKey, editCtl, g
    first := Format("{:04}{:02}01", viewY, viewM)
    dow := Integer(FormatTime(first, "WDay"))
    d := i - (dow - 1)
    if (d < 1 || d > DaysIn(viewY, viewM))
        return
    selKey := Format("{:04}-{:02}-{:02}", viewY, viewM, d)
    RenderMonth()
    try WinActivate("ahk_id " g.Hwnd)   ; now take the focus: typing an entry needs it
    editCtl.Focus()
}

AddEntry(*) {
    global editCtl, events, selKey, gcal
    t := Trim(editCtl.Text)
    if (t = "")
        return
    from := "", to := "", title := t
    if RegExMatch(t, "^(\d{1,2}:\d{2})(?:-(\d{1,2}:\d{2}))?\s+(.+)$", &m) {
        from := m[1], to := m[2], title := m[3]
    }
    if gcal {
        SetStatus("Google: adding...")
        ok := Gcal("add " selKey " " Quote(title) (from != "" ? " " from (to != "" ? " " to : "") : ""))
        SetStatus(ok ? "Google: added" : "Google: add failed (see glance-gcal.log)")
        if ok {
            editCtl.Text := ""
            FetchMonth()
        }
    } else {
        if !events.Has(selKey)
            events[selKey] := []
        events[selKey].Push({time: from, title: title, id: ""})
        SaveEvents()
        editCtl.Text := ""
        RenderMonth()
    }
    editCtl.Focus()
    Log("entry added on " selKey)
}

DeleteEntry(ctl, info) {
    global events, selKey, listCtl, gcal
    idx := listCtl.Value
    if (idx < 1 || !events.Has(selKey) || idx > events[selKey].Length)
        return
    if gcal {
        id := events[selKey][idx].id
        SetStatus("Google: deleting...")
        ok := Gcal("delete " Quote(id))
        SetStatus(ok ? "Google: deleted" : "Google: delete failed (see glance-gcal.log)")
        if ok
            FetchMonth()
    } else {
        events[selKey].RemoveAt(idx)
        if (events[selKey].Length = 0)
            events.Delete(selKey)
        SaveEvents()
        RenderMonth()
    }
    Log("entry deleted on " selKey)
}

; ---- Google backend ----
Quote(s) {
    return '"' StrReplace(s, '"', "'") '"'
}

PsCommand(args) {
    global GcalScript
    return 'powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "' GcalScript '" ' args
}

Gcal(args) {
    ; synchronous (add / delete): a second or so, with the window open
    try {
        code := RunWait(PsCommand(args), A_ScriptDir, "Hide")
        if (code != 0)
            Log("gcal " SubStr(args, 1, 6) ": exit " code)
        return code = 0
    } catch as e {
        Log("gcal run failed: " e.Message)
        return false
    }
}

FetchMonth() {
    ; asynchronous (list): the window keeps showing the last cache, then refreshes
    global fetchPid, fetchedYM, viewY, viewM
    if fetchPid && ProcessExist(fetchPid)
        return                       ; one at a time; the timer re-fetches if the month moved
    fetchedYM := Format("{:04}-{:02}", viewY, viewM)
    try {
        Run(PsCommand("list " fetchedYM), A_ScriptDir, "Hide", &pid)
        fetchPid := pid
        SetStatus("Google: syncing " fetchedYM " ...")
        SetTimer(CheckFetch, 250)
    } catch as e {
        Log("gcal list failed to start: " e.Message)
        SetStatus("Google: cannot start PowerShell")
    }
}

CheckFetch() {
    global fetchPid, fetchedYM, viewY, viewM
    if ProcessExist(fetchPid)
        return
    SetTimer(CheckFetch, 0)
    fetchPid := 0
    LoadCache()
    RenderMonth()
    SetStatus("Google: " FormatTime(, "HH:mm") " " fetchedYM)
    if (fetchedYM != Format("{:04}-{:02}", viewY, viewM))
        FetchMonth()                 ; the month moved while we were fetching
}

LoadCache() {
    global events, GcalCache
    events := Map()
    if !FileExist(GcalCache)
        return
    for line in StrSplit(FileRead(GcalCache, "UTF-8"), "`n", "`r") {
        if (line = "")
            continue
        f := StrSplit(line, "`t")
        if (f.Length < 3)
            continue
        key := f[1]
        if !events.Has(key)
            events[key] := []
        events[key].Push({time: f[2], title: f[3], id: f.Length >= 4 ? f[4] : ""})
    }
}

SetStatus(s) {
    global statusCtl
    try statusCtl.Text := s
}

; ---- local backend ----
LoadEvents() {
    global events, DataFile
    events := Map()
    if !FileExist(DataFile)
        return
    for line in StrSplit(FileRead(DataFile, "UTF-8"), "`n", "`r") {
        if (line = "")
            continue
        p := InStr(line, "`t")
        if !p
            continue
        key := SubStr(line, 1, p - 1), rest := SubStr(line, p + 1)
        t := "", title := rest
        if RegExMatch(rest, "^(\d{1,2}:\d{2})\s+(.+)$", &m) {
            t := m[1], title := m[2]
        }
        if !events.Has(key)
            events[key] := []
        events[key].Push({time: t, title: title, id: ""})
    }
}

SaveEvents() {
    global events, DataFile
    keys := []
    for k in events
        keys.Push(k)
    n := keys.Length
    loop n - 1 {
        i := A_Index
        loop n - i {
            j := A_Index
            if (StrCompare(keys[j], keys[j + 1]) > 0) {
                tmp := keys[j], keys[j] := keys[j + 1], keys[j + 1] := tmp
            }
        }
    }
    out := ""
    for k in keys
        for e in events[k]
            out .= k "`t" (e.time != "" ? e.time " " : "") e.title "`r`n"
    f := FileOpen(DataFile, "w", "UTF-8-RAW")
    f.Write(out)
    f.Close()
}

CloseStaleCopies() {
    ; Another copy of this script (e.g. one started from github-export\) would
    ; answer F16 too. Ask it to exit.
    prev := A_DetectHiddenWindows
    DetectHiddenWindows(true)
    for h in WinGetList("ahk_class AutoHotkey") {
        t := WinGetTitle("ahk_id " h)
        if InStr(t, "glance-notes.ahk") && !InStr(t, A_ScriptFullPath) {
            try PostMessage(0x0111, 65307, 0, , "ahk_id " h)   ; WM_COMMAND ID_FILE_EXIT
            Log("asked a stale copy of this script (another folder) to exit")
        }
    }
    DetectHiddenWindows(prev)
}

Log(msg) {
    global LogFile
    try FileAppend(FormatTime(, "yyyy-MM-dd HH:mm:ss") " " msg "`n", LogFile, "UTF-8")
}
