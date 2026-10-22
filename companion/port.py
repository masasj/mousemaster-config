#!/usr/bin/env python3
"""Mechanical port of the four resident scripts into mm-companion modules.
usage: python3 companion/port.py <mousemaster_92 folder>
The logic of each script is left as it is. What changes: every function and state variable
gets the module prefix; Log(x) becomes Log("module", x); the Log and CloseStaleCopies
functions are dropped (core has them); settings move to companion\settings.ahk and their
references are renamed; everything the old script ran at load time (timers, hooks, the
start line) moves into <Prefix>_Init(); static hotkeys become Core_Hotkeys() calls there."""
import os, re, sys
root = sys.argv[1] if len(sys.argv) > 1 else '.'
MODULES = [
    # src, dst, prefix, {old setting name: new name}, module tag
    ('ibeam-watch.ahk',     'companion/mousemaster/cursor.ahk', 'Cursor',
        {'POLL_MS': 'Cursor_PollMs', 'RESEND_MS': 'Cursor_ResendMs', 'LogFile': None}, 'cursor'),
    ('snipaste-unpin.ahk',  'companion/mousemaster/unpin.ahk',  'Unpin',
        {'SCAN_MS': 'Unpin_ScanMs', 'LogFile': None}, 'unpin'),
    ('glance.ahk',          'companion/mousemaster/glance.ahk', 'Glance',
        {'CalendarUrl': 'Glance_CalendarUrl', 'WinW': 'Glance_WinW', 'WinH': 'Glance_WinH', 'BrowserExe': 'Glance_BrowserExe',
         'Prewarm': 'Glance_Prewarm', 'PrewarmDelayMs': 'Glance_PrewarmDelayMs', 'LogFile': None}, 'glance'),
    ('claude-to-front.ahk', 'companion/efficiency/front.ahk',   'Front',
        {'IDLE_MS': 'Front_IdleMs', 'TOAST_MS': 'Front_ToastMs', 'REQUIRE_TOAST': 'Front_RequireToast',
         'RETRY_MS': 'Front_RetryMs', 'LogFile': None}, 'front'),
]
DROP_FUNCS = {'Log', 'CloseStaleCopies'}
DIRECTIVES = re.compile(r'^(#Requires|#SingleInstance|Persistent\(\)|SetTitleMatchMode\(|DetectHiddenWindows\(|CoordMode\()')
FUNC = re.compile(r'^([A-Za-z_]\w*)\(([^)]*)\)\s*\{\s*$')
HOTKEY = re.compile(r'^([!+^#]*)(\w+)::(\w+)\(\)\s*$')
def port(src, dst, prefix, settings, tag):
    text = open(os.path.join(root, src), 'rb').read().decode('ascii').replace('\r\n', '\n')
    lines = text.split('\n')
    header, i = [], 0
    while i < len(lines) and (lines[i].startswith(';') or lines[i].strip() == ''):
        header.append(lines[i]); i += 1
    funcs, top, hotkeys = {}, [], []
    cur, body, depth = None, [], 0
    for line in lines[i:]:
        s = line.strip()
        if cur is None:
            m = FUNC.match(line)
            if m:
                cur, body, depth = m.group(1), [line], 1
                continue
            if DIRECTIVES.match(s) or s == '':
                continue
            h = HOTKEY.match(s)
            if h:
                hotkeys.append((h.group(2), h.group(3)))
                continue
            top.append(line)
        else:
            body.append(line)
            depth += line.count('{') - line.count('}')
            if depth == 0:
                funcs[cur] = body; cur = None
    # globals defined at the top level: `global X := ...`, `X := ...` and comma lists
    state = []
    keep_top, init = [], []
    for line in top:
        s = line.strip()
        m = re.match(r'^(?:global\s+)?([A-Za-z_]\w*)\s*:=\s*(.*)$', s)
        if m and not s.startswith('if ') and not re.match(r'^(SetTimer|DllCall|OnMessage|Log|CloseStaleCopies|SetTimer)\(', s):
            names = re.findall(r'(?:^|,\s*)([A-Za-z_]\w*)\s*:=', s.replace('global ', '', 1))
            for n in names:
                if n in settings:
                    continue           # lives in settings.ahk now (or, LogFile, is gone)
                state.append(n)
            # rebuild the line with only the non-setting assignments
            parts = [p.strip() for p in re.split(r',(?=\s*[A-Za-z_]\w*\s*:=)', s.replace('global ', '', 1))]
            parts = [p for p in parts if re.match(r'^([A-Za-z_]\w*)', p).group(1) not in settings]
            if parts:
                keep_top.append('global ' + ', '.join(parts))
            continue
        if s.startswith(';'):
            continue
        if re.match(r'^CloseStaleCopies\(\)', s):
            continue
        init.append(line)
    # names to rename: functions (not dropped) and state variables
    rename = {}
    for f in funcs:
        if f not in DROP_FUNCS:
            rename[f] = f'{prefix}_{f}'
    for v in state:
        rename[v] = f'{prefix}_{v}'
    for old, new in settings.items():
        if new:
            rename[old] = new
    def fix(code):
        code = re.sub(r'\bLog\(', f'Log("{tag}", ', code)
        for old, new in rename.items():
            code = re.sub(rf'\b{re.escape(old)}\b', new, code)
        return code
    out = header[:]
    out.append(f'; Ported into mm-companion on 2026-10-22: functions and state carry the {prefix}_ prefix, the')
    out.append(f'; settings sit in companion\\settings.ahk, and what ran at load time is now {prefix}_Init().')
    out.append('')
    for line in keep_top:
        out.append(fix(line))
    out.append('')
    out.append(f'{prefix}_Init() {{')
    if state:
        out.append('    global ' + ', '.join(f'{prefix}_{v}' for v in state))
    for line in init:
        out.append('    ' + fix(line.strip()))
    for key, fn in hotkeys:
        pass
    seen = []
    for key, fn in hotkeys:
        if key not in seen:
            seen.append(key)
            out.append(f'    Core_Hotkeys("{key}", (*) => {prefix}_{fn}())')
    out.append('}')
    out.append('')
    for f, body in funcs.items():
        if f in DROP_FUNCS:
            continue
        for line in body:
            out.append(fix(line))
        out.append('')
    result = '\n'.join(out).rstrip('\n') + '\n'
    result.encode('ascii')
    path = os.path.join(root, dst)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    open(path, 'w', encoding='ascii', newline='').write(result.replace('\n', '\r\n'))
    print(f'{src} -> {dst}: {len(funcs) - len(DROP_FUNCS & set(funcs))} functions, {len(state)} state vars, {len(seen)} hotkeys, {len(init)} init lines')
for m in MODULES:
    port(*m)
