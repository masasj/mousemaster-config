# glance-gcal.ps1  (Windows PowerShell 5.1 / PowerShell 7)
#
# Google Calendar (primary calendar) for glance.ahk: list a month, add, delete.
# Setup once: see GLANCE-GCAL-SETUP.md (an OAuth "Desktop app" client of your own).
#   glance-gcal.ps1 auth                      opens the browser, saves glance-gcal-token.json
#   glance-gcal.ps1 list 2026-10              writes glance-gcal-cache.txt (and prints it)
#   glance-gcal.ps1 add 2026-10-20 "title"    all-day event
#   glance-gcal.ps1 add 2026-10-20 "title" 14:00 [15:30]   timed event (default 60 min)
#   glance-gcal.ps1 delete <eventId>
# Files next to this script (never put them in a repo):
#   glance-gcal-client.json   the OAuth client you downloaded ({"installed":{"client_id":..,"client_secret":..}})
#   glance-gcal-token.json    refresh/access token written by "auth"
#   glance-gcal-cache.txt     last listing: YYYY-MM-DD<TAB>HH:MM<TAB>title<TAB>eventId (HH:MM empty = all-day)
# Exit code 0 on success; errors go to glance-gcal.log and the exit code is 1.

param(
    [Parameter(Position = 0)] [string] $Command = "",
    [Parameter(Position = 1)] [string] $Arg1 = "",
    [Parameter(Position = 2)] [string] $Arg2 = "",
    [Parameter(Position = 3)] [string] $Arg3 = "",
    [Parameter(Position = 4)] [string] $Arg4 = ""
)

$ErrorActionPreference = "Stop"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$Here = Split-Path -Parent $MyInvocation.MyCommand.Path
$ClientFile = Join-Path $Here "glance-gcal-client.json"
$TokenFile = Join-Path $Here "glance-gcal-token.json"
$CacheFile = Join-Path $Here "glance-gcal-cache.txt"
$LogFile = Join-Path $Here "glance-gcal.log"
$Scope = "https://www.googleapis.com/auth/calendar.events"
$Port = 53682
$Utf8 = New-Object System.Text.UTF8Encoding($false)

function Log($msg) {
    try { Add-Content -Path $LogFile -Value ("{0} {1}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $msg) -Encoding UTF8 } catch {}
}

function Read-Json($path) {
    return (Get-Content -Path $path -Raw -Encoding UTF8) | ConvertFrom-Json
}

function Write-Json($path, $obj) {
    [IO.File]::WriteAllText($path, ($obj | ConvertTo-Json -Depth 5), $Utf8)
}

function Get-Client {
    if (!(Test-Path $ClientFile)) { throw "glance-gcal-client.json not found next to the script (see GLANCE-GCAL-SETUP.md)" }
    $j = Read-Json $ClientFile
    $c = if ($j.installed) { $j.installed } elseif ($j.web) { $j.web } else { $j }
    if (!$c.client_id) { throw "client_id missing in glance-gcal-client.json" }
    return $c
}

function Base64Url([byte[]] $bytes) {
    return [Convert]::ToBase64String($bytes).TrimEnd("=").Replace("+", "-").Replace("/", "_")
}

function Do-Auth {
    $c = Get-Client
    $rng = New-Object System.Security.Cryptography.RNGCryptoServiceProvider
    $vb = New-Object byte[] 48
    $rng.GetBytes($vb)
    $verifier = Base64Url $vb
    $sha = [System.Security.Cryptography.SHA256]::Create()
    $challenge = Base64Url ($sha.ComputeHash([Text.Encoding]::ASCII.GetBytes($verifier)))
    $redirect = "http://127.0.0.1:$Port/"
    $url = "https://accounts.google.com/o/oauth2/v2/auth?client_id=$([Uri]::EscapeDataString($c.client_id))" +
           "&redirect_uri=$([Uri]::EscapeDataString($redirect))&response_type=code" +
           "&scope=$([Uri]::EscapeDataString($Scope))&access_type=offline&prompt=consent" +
           "&code_challenge=$challenge&code_challenge_method=S256"
    # A plain TCP listener on the loopback: no URL reservation needed (HttpListener would need one).
    $listener = New-Object System.Net.Sockets.TcpListener -ArgumentList @([Net.IPAddress]::Loopback, $Port)
    $listener.Start()
    Write-Host "A browser window opens: choose the Google account and allow calendar access."
    Write-Host "If Google warns that the app is not verified, use Advanced -> Go to glance (unsafe): it is your own app."
    Start-Process $url
    $code = $null
    try {
        $client = $listener.AcceptTcpClient()
        $stream = $client.GetStream()
        $reader = New-Object IO.StreamReader($stream)
        $requestLine = $reader.ReadLine()
        while (($line = $reader.ReadLine()) -ne $null -and $line -ne "") { }
        if ($requestLine -match "GET /\?([^ ]*) HTTP") {
            $q = [Web.HttpUtility]::ParseQueryString($matches[1])
            $code = $q["code"]
            $err = $q["error"]
        }
        $body = if ($code) { "<html><body style='font-family:sans-serif'><h2>glance: connected.</h2>You can close this tab.</body></html>" }
                else { "<html><body style='font-family:sans-serif'><h2>glance: no code received ($err).</h2></body></html>" }
        $bytes = [Text.Encoding]::UTF8.GetBytes($body)
        $header = "HTTP/1.1 200 OK`r`nContent-Type: text/html; charset=utf-8`r`nContent-Length: $($bytes.Length)`r`nConnection: close`r`n`r`n"
        $hb = [Text.Encoding]::ASCII.GetBytes($header)
        $stream.Write($hb, 0, $hb.Length)
        $stream.Write($bytes, 0, $bytes.Length)
        $stream.Flush()
        $client.Close()
    } finally {
        $listener.Stop()
    }
    if (!$code) { throw "no authorization code received" }
    $body = @{
        code = $code; client_id = $c.client_id; client_secret = $c.client_secret
        redirect_uri = $redirect; grant_type = "authorization_code"; code_verifier = $verifier
    }
    $tok = Invoke-RestMethod -Method Post -Uri "https://oauth2.googleapis.com/token" -Body $body
    if (!$tok.refresh_token) { throw "no refresh_token in the response (remove the app's access at myaccount.google.com/permissions and run auth again)" }
    $save = @{
        refresh_token = $tok.refresh_token; access_token = $tok.access_token
        expires_at = (Get-Date).AddSeconds([int]$tok.expires_in - 60).ToString("o")
    }
    Write-Json $TokenFile $save
    Log "auth ok"
    Write-Host "Token saved: $TokenFile"
}

function Get-AccessToken {
    if (!(Test-Path $TokenFile)) { throw "not connected yet: run glance-gcal.ps1 auth" }
    $t = Read-Json $TokenFile
    if ($t.access_token -and $t.expires_at -and ([DateTime]::Parse($t.expires_at) -gt (Get-Date))) {
        return $t.access_token
    }
    $c = Get-Client
    $body = @{ refresh_token = $t.refresh_token; client_id = $c.client_id; client_secret = $c.client_secret; grant_type = "refresh_token" }
    $r = Invoke-RestMethod -Method Post -Uri "https://oauth2.googleapis.com/token" -Body $body
    $save = @{
        refresh_token = $t.refresh_token; access_token = $r.access_token
        expires_at = (Get-Date).AddSeconds([int]$r.expires_in - 60).ToString("o")
    }
    Write-Json $TokenFile $save
    return $r.access_token
}

function Invoke-Gcal($method, $path, $bodyObj) {
    $token = Get-AccessToken
    $headers = @{ Authorization = "Bearer $token" }
    $uri = "https://www.googleapis.com/calendar/v3/$path"
    if ($bodyObj -ne $null) {
        $json = $bodyObj | ConvertTo-Json -Depth 5 -Compress
        return Invoke-RestMethod -Method $method -Uri $uri -Headers $headers -ContentType "application/json; charset=utf-8" -Body ([Text.Encoding]::UTF8.GetBytes($json))
    }
    return Invoke-RestMethod -Method $method -Uri $uri -Headers $headers
}

function Rfc3339($dt) {
    return $dt.ToString("yyyy-MM-ddTHH:mm:sszzz")
}

function Do-List($ym) {
    if ($ym -notmatch "^(\d{4})-(\d{2})$") { throw "list needs YYYY-MM" }
    $y = [int]$matches[1]; $m = [int]$matches[2]
    $first = Get-Date -Year $y -Month $m -Day 1 -Hour 0 -Minute 0 -Second 0 -Millisecond 0
    $next = $first.AddMonths(1)
    $path = "calendars/primary/events?singleEvents=true&orderBy=startTime&maxResults=2500" +
            "&timeMin=$([Uri]::EscapeDataString((Rfc3339 $first)))&timeMax=$([Uri]::EscapeDataString((Rfc3339 $next)))"
    $lines = New-Object System.Collections.Generic.List[string]
    do {
        $r = Invoke-Gcal "Get" $path $null
        foreach ($e in $r.items) {
            if ($e.status -eq "cancelled") { continue }
            $title = if ($e.summary) { $e.summary } else { "(no title)" }
            $title = $title -replace "[`t`r`n]", " "
            if ($e.start.date) {
                # all-day events run from start.date to end.date (exclusive): one line per day inside the month
                $d = [DateTime]::ParseExact($e.start.date, "yyyy-MM-dd", $null)
                $end = [DateTime]::ParseExact($e.end.date, "yyyy-MM-dd", $null)
                while ($d -lt $end) {
                    if ($d -ge $first -and $d -lt $next) { $lines.Add(("{0}`t`t{1}`t{2}" -f $d.ToString("yyyy-MM-dd"), $title, $e.id)) }
                    $d = $d.AddDays(1)
                }
            } else {
                $s = [DateTime]::Parse($e.start.dateTime).ToLocalTime()
                $lines.Add(("{0}`t{1}`t{2}`t{3}" -f $s.ToString("yyyy-MM-dd"), $s.ToString("HH:mm"), $title, $e.id))
            }
        }
        $pageToken = $r.nextPageToken
        if ($pageToken) { $path = $path -replace "&pageToken=[^&]*", ""; $path += "&pageToken=$pageToken" }
    } while ($pageToken)
    $sorted = @($lines | Sort-Object)
    [IO.File]::WriteAllLines($CacheFile, [string[]]$sorted, $Utf8)
    $sorted | ForEach-Object { Write-Output $_ }
    Log ("list {0}: {1} line(s)" -f $ym, $sorted.Count)
}

function Do-Add($date, $title, $from, $to) {
    if ($date -notmatch "^\d{4}-\d{2}-\d{2}$") { throw "add needs YYYY-MM-DD" }
    if (!$title) { throw "add needs a title" }
    if ($from) {
        if ($from -notmatch "^\d{1,2}:\d{2}$") { throw "time must be HH:MM" }
        $start = [DateTime]::Parse("$date $from")
        $end = if ($to) { [DateTime]::Parse("$date $to") } else { $start.AddMinutes(60) }
        if ($end -le $start) { $end = $start.AddMinutes(60) }
        # the offset inside the RFC 3339 string carries the zone (a Windows zone id would be rejected)
        $body = @{ summary = $title; start = @{ dateTime = (Rfc3339 $start) }; end = @{ dateTime = (Rfc3339 $end) } }
    } else {
        $d = [DateTime]::ParseExact($date, "yyyy-MM-dd", $null)
        $body = @{ summary = $title; start = @{ date = $date }; end = @{ date = $d.AddDays(1).ToString("yyyy-MM-dd") } }
    }
    $r = Invoke-Gcal "Post" "calendars/primary/events" $body
    Write-Output $r.id
    Log ("add {0} {1}: {2}" -f $date, $from, $r.id)
}

function Do-Delete($id) {
    if (!$id) { throw "delete needs an eventId" }
    Invoke-Gcal "Delete" "calendars/primary/events/$([Uri]::EscapeDataString($id))" $null | Out-Null
    Log "delete $id"
}

try {
    Add-Type -AssemblyName System.Web
    switch ($Command) {
        "auth"   { Do-Auth }
        "list"   { Do-List $Arg1 }
        "add"    { Do-Add $Arg1 $Arg2 $Arg3 $Arg4 }
        "delete" { Do-Delete $Arg1 }
        default  { Write-Host "usage: glance-gcal.ps1 auth | list YYYY-MM | add YYYY-MM-DD title [HH:MM [HH:MM]] | delete eventId"; exit 2 }
    }
    exit 0
} catch {
    $msg = $_.Exception.Message
    if ($_.ErrorDetails -and $_.ErrorDetails.Message) { $msg += " / " + $_.ErrorDetails.Message }
    Log ("ERROR {0}: {1}" -f $Command, $msg)
    Write-Host "ERROR: $msg"
    exit 1
}
