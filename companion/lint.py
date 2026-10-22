#!/usr/bin/env python3
"""lint for mm-companion (run on the VM; AutoHotkey itself cannot run there).
usage: python3 companion/lint.py <folder with mm-companion.ahk>
Checks: ASCII + CRLF; #Include targets exist; no function defined twice across files;
each module has <Prefix>_Init; Log() calls carry the module tag; hotkeys registered once
and only through Core_Hotkeys inside Init; module files run nothing at load time except
'global x := ...'; every call resolves to a defined function or a known built-in."""
import os, re, sys
root = sys.argv[1] if len(sys.argv) > 1 else '.'
entry = os.path.join(root, 'mm-companion.ahk')
files = [entry]
errs, warns = [], []
BUILTIN = set('''SetTimer WinExist WinGetList WinGetTitle WinGetProcessName WinGetClass WinGetPos WinGetMinMax
WinGetExStyle WinActive WinActivate WinShow WinHide WinMinimize WinRestore WinMove WinWaitActive WinWait WinClose
WinSetTransparent WinSetAlwaysOnTop DllCall NumPut NumGet Buffer Map Array Format FileExist FileGetSize FileDelete
FileAppend FileRead FormatTime InStr SubStr StrLower StrUpper StrLen StrSplit StrReplace RegExMatch RegExReplace Trim
Run RunWait ProcessExist ProcessClose Sleep PostMessage SendMessage SendInput Send SendEvent GetKeyState MouseGetPos
MouseMove MonitorGet MonitorGetCount MonitorGetWorkArea MonitorGetPrimary SysGet TrayTip ToolTip Gui ComObject ComCall
ComObjGet Hotkey OnMessage OnError OnExit Reload ExitApp Persistent SetTitleMatchMode DetectHiddenWindows CoordMode
SetWinDelay SetControlDelay Min Max Abs Round Floor Ceil Mod Integer Float String Number IsSet IsObject Type Critical
Thread ProcessWait ProcessWaitClose EnvGet IniRead IniWrite MsgBox InputBox Random Chr Ord Func ObjBindMethod
ClipWait HasProp HasMethod GetKeyName GetKeyVK GetKeySC KeyWait ControlSend ControlClick ControlGetFocus WinGetID
WinGetStyle WinSetStyle WinSetExStyle WinGetTransparent WinGetText DirExist FileOpen SplitPath A_TrayMenu'''.split())
def read(p):
    b = open(p, 'rb').read()
    try: b.decode('ascii')
    except UnicodeDecodeError: errs.append(f'{p}: not ASCII')
    if b'\n' in b.replace(b'\r\n', b''): errs.append(f'{p}: a line without CRLF')
    return b.decode('ascii', 'replace').replace('\r\n', '\n')
src = {}
text = read(entry); src[entry] = text
for m in re.finditer(r'^#Include\s+(.+?)\s*$', text, re.M):
    p = m.group(1).replace('%A_ScriptDir%', root).replace('\\', os.sep)
    if not os.path.exists(p): errs.append(f'#Include target missing: {m.group(1)}')
    else: files.append(p); src[p] = read(p)
# function definitions and duplicates
defs = {}
for p, t in src.items():
    for m in re.finditer(r'^([A-Za-z_]\w*)\(([^)]*)\)\s*\{', t, re.M):
        name = m.group(1)
        if name in defs: errs.append(f'{name}() defined twice: {defs[name]} and {p}')
        defs[name] = p
# modules: prefix, Init, load-time statements, Log tags, hotkeys
hot = {}
for p, t in src.items():
    base = os.path.basename(p)
    if base in ('mm-companion.ahk', 'settings.ahk', 'core.ahk'): continue
    prefix = {'cursor.ahk': 'Cursor', 'unpin.ahk': 'Unpin', 'glance.ahk': 'Glance', 'front.ahk': 'Front', 'ocdup.ahk': 'OcDup'}.get(base)
    if not prefix: warns.append(f'{p}: unknown module name (no prefix rule)'); continue
    if f'{prefix}_Init' not in defs: errs.append(f'{p}: {prefix}_Init() missing')
    for m in re.finditer(r'^([A-Za-z_]\w*)\(', t, re.M):
        if not m.group(1).startswith(prefix + '_'): errs.append(f'{p}: function {m.group(1)} lacks the {prefix}_ prefix')
    depth = 0
    for i, line in enumerate(t.split('\n'), 1):
        s = line.strip()
        if depth == 0 and s and not s.startswith(';') and not s.startswith('#') and not re.match(r'^global \w+ *:=', s) \
                and not re.match(r'^[A-Za-z_]\w*\([^)]*\)\s*\{', s) and s != '}':
            errs.append(f'{p}:{i}: runs at load time (move into {prefix}_Init): {s[:60]}')
        depth += s.count('{') - s.count('}')
    if '::' in t and re.search(r'^\S+::', t, re.M): errs.append(f'{p}: a static hotkey (key::) - register through Core_Hotkeys in Init')
    for m in re.finditer(r'\bLog\(\s*([^,\)]*)', t):
        if not re.match(r'^"[a-z]+"$', m.group(1).strip()): errs.append(f'{p}: Log() without a module tag: Log({m.group(1)[:30]}')
    for m in re.finditer(r'Core_Hotkeys?\(\s*"([^"]+)"', t):
        k = m.group(1)
        if k in hot: errs.append(f'hotkey {k} registered in {hot[k]} and {p}')
        hot[k] = p
# unresolved calls
for p, t in src.items():
    code = re.sub(r'"(?:[^"`]|`.)*"', '""', t)
    code = re.sub(r';.*', '', code)
    for m in re.finditer(r'(?<![\w.])([A-Za-z_]\w*)\(', code):
        n = m.group(1)
        if n not in defs and n not in BUILTIN and n not in ('if', 'while', 'for', 'return', 'try', 'catch', 'else', 'loop', 'switch', 'case'):
            warns.append(f'{p}: call to unknown {n}()')
for e in errs: print('ERROR', e)
for w in sorted(set(warns)): print('warn ', w)
print(f'{len(files)} files, {len(defs)} functions, {len(hot)} hotkeys, {len(errs)} errors, {len(set(warns))} warnings')
sys.exit(1 if errs else 0)
