<#
.SYNOPSIS
  Live monitor and test logger for the PresenceWake board (LOLIN S2 Mini + HLK-LD2410C).

.DESCRIPTION
  Reads the board's serial output, timestamps and colors it, writes a CSV log, and prints a
  pass/fail summary per test phase when you quit.

  Keys while running:
    1 = walk-in      (walk into the room)
    2 = sit-still    (sit and work normally, 2-3 minutes)
    3 = leave        (leave and stay out at least 90 seconds)
    4 = empty-room   (room empty, 5+ minutes; press it on your way out)
    0 = no label
    q = quit and show summary

  Close the Arduino Serial Monitor first. Only one program can hold the COM port.

.EXAMPLE
  powershell.exe -ExecutionPolicy Bypass -File .\Test-PresenceWake.ps1 -Port COM4
#>
param(
    [string]$Port   = 'COM4',
    [int]   $Baud   = 115200,
    [string]$LogDir = $PSScriptRoot
)

$phaseNames = @{ '0' = 'none'; '1' = 'walk-in'; '2' = 'sit-still'; '3' = 'leave'; '4' = 'empty-room' }
$phase   = 'none'
$stats   = [ordered]@{}
$lastOut = $null
$buf     = ''

function Get-Stats([string]$p) {
    if (-not $stats.Contains($p)) {
        $stats[$p] = [ordered]@{ Heartbeats = 0; Out1 = 0; Out0 = 0; Present = 0; Absent = 0; Actions = 0; Flips = 0 }
    }
    return $stats[$p]
}

$logFile = Join-Path $LogDir ('presence-log-{0:yyyyMMdd-HHmmss}.csv' -f (Get-Date))
'Time,Phase,Type,Line' | Set-Content -Path $logFile -Encoding ASCII

function Write-Log([string]$type, [string]$line) {
    Add-Content -Path $logFile -Encoding ASCII -Value ('{0:yyyy-MM-dd HH:mm:ss},{1},{2},"{3}"' -f (Get-Date), $phase, $type, ($line -replace '"', '""'))
}

function Open-Port {
    $p = New-Object System.IO.Ports.SerialPort $Port, $Baud, 'None', 8, 'One'
    $p.DtrEnable = $true    # some USB CDC devices hold output until DTR is asserted
    $p.RtsEnable = $true    # with RTS off, closing the port left this board in upload mode (see BUILD.md)
    $p.Open()
    return $p
}

function Process-Line([string]$line) {
    $s = Get-Stats $phase
    $type = 'OTHER'; $color = 'Gray'
    if ($line -match '^out=(\d) present=(\d)') {
        $type = 'HB'; $s.Heartbeats++
        if ($Matches[1] -eq '1') { $s.Out1++ } else { $s.Out0++ }
        if ($null -ne $script:lastOut -and $Matches[1] -ne $script:lastOut) { $s.Flips++; $color = 'Yellow' }
        $script:lastOut = $Matches[1]
    }
    elseif ($line -match '\[STATE\] PRESENT') { $type = 'PRESENT'; $s.Present++; $color = 'Green' }
    elseif ($line -match '\[STATE\] ABSENT')  { $type = 'ABSENT';  $s.Absent++;  $color = 'Red' }
    elseif ($line -match '\[ACTION\]')        { $type = 'ACTION';  $s.Actions++; $color = 'Magenta' }
    Write-Host ('{0:HH:mm:ss} [{1,-10}] {2}' -f (Get-Date), $phase, $line) -ForegroundColor $color
    Write-Log $type $line
}

try { $sp = Open-Port }
catch {
    Write-Host "Could not open $Port : $($_.Exception.Message)" -ForegroundColor Red
    Write-Host 'Is the Arduino Serial Monitor (or another program) still holding the port?'
    exit 1
}

Write-Host "Connected to $Port at $Baud baud. Logging to $logFile" -ForegroundColor Cyan
Write-Host 'Keys: 1 walk-in | 2 sit-still | 3 leave | 4 empty-room | 0 none | q quit' -ForegroundColor Cyan
Write-Host 'Heartbeats arrive every 5 s. Yellow = OUT changed since the last heartbeat.' -ForegroundColor Cyan
$null = Get-Stats $phase

try {
    while ($true) {
        if ([Console]::KeyAvailable) {
            $k = [Console]::ReadKey($true).KeyChar.ToString().ToLower()
            if ($k -eq 'q') { break }
            if ($phaseNames.ContainsKey($k)) {
                $phase = $phaseNames[$k]
                $null = Get-Stats $phase
                Write-Host ('---- phase: {0} ----' -f $phase) -ForegroundColor Cyan
                Write-Log 'PHASE' $phase
            }
        }

        try {
            if ($sp.BytesToRead -gt 0) { $buf += $sp.ReadExisting() }
            else { Start-Sleep -Milliseconds 50; continue }
        }
        catch {
            # Port vanished, usually because the board was reset. Try to reconnect for 15 s.
            Write-Host "Port lost ($($_.Exception.Message)). Reconnecting..." -ForegroundColor Red
            Write-Log 'PORT' 'lost'
            try { $sp.Dispose() } catch { }
            $sp = $null
            for ($i = 0; $i -lt 15 -and $null -eq $sp; $i++) {
                Start-Sleep -Seconds 1
                try { $sp = Open-Port } catch { $sp = $null }
            }
            if ($null -eq $sp) { Write-Host "Could not reopen $Port. Check Device Manager for the port number." -ForegroundColor Red; break }
            Write-Host 'Reconnected.' -ForegroundColor Cyan
            Write-Log 'PORT' 'reconnected'
            $buf = ''
            continue
        }

        while (($i = $buf.IndexOf("`n")) -ge 0) {
            $line = $buf.Substring(0, $i).Trim()
            $buf  = $buf.Substring($i + 1)
            if ($line) { Process-Line $line }
        }
    }
}
finally {
    if ($sp -and $sp.IsOpen) { $sp.Close() }

    Write-Host ''
    Write-Host '==== Summary ====' -ForegroundColor Cyan
    $rows = foreach ($p in $stats.Keys) {
        $s = $stats[$p]
        $verdict = switch ($p) {
            'walk-in'    { if ($s.Present -ge 1) { 'PASS' } else { 'FAIL: no PRESENT' } }
            'sit-still'  { if ($s.Out0 -eq 0 -and $s.Absent -eq 0) { 'PASS' } else { 'FAIL: radar lost you while seated' } }
            'leave'      { if ($s.Absent -ge 1) { 'PASS' } else { 'NOT YET: no ABSENT (wait 60 s + radar hold time)' } }
            'empty-room' { if ($s.Out1 -eq 0 -and $s.Present -eq 0) { 'PASS' } else { 'FAIL: false detection in empty room' } }
            default      { '-' }
        }
        [pscustomobject]@{
            Phase = $p; Heartbeats = $s.Heartbeats; 'OUT=1' = $s.Out1; 'OUT=0' = $s.Out0
            Flips = $s.Flips; PRESENT = $s.Present; ABSENT = $s.Absent; Actions = $s.Actions; Result = $verdict
        }
    }
    $rows | Format-Table -AutoSize | Out-Host
    Write-Host "Log: $logFile"
}
