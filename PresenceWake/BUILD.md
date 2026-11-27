# PresenceWake: build, flash and test

How to compile, upload and check `PresenceWake.ino` on this machine. Everything here was run
against the real board on 2026-11-23 to 2026-11-25 unless a line says otherwise.

## What it does

A LOLIN S2 Mini (ESP32-S2) with an HLK-LD2410C radar, plugged into the PC by USB-C. It shows up
as a USB keyboard and mouse.

| Event | Action |
|---|---|
| Someone arrives (radar OUT high for 300 ms) | 1-pixel mouse nudge, then a Left Ctrl tap |
| Nobody in view for 60 s | Win+L |

The mouse nudge wakes a sleeping display. The Ctrl tap lifts the Windows lock screen cover so the
PIN box is showing; a mouse move alone does not do that. Ctrl was chosen because it types nothing
if the PC happens to be unlocked. The board never types a password.

## Settings (top of the sketch)

| Constant | Value | Meaning |
|---|---|---|
| `DRY_RUN` | `false` | `true` logs actions to serial but sends no keys or mouse movement |
| `ENABLE_LOCK_ON_LEAVE` | `true` | Send Win+L when the room empties |
| `PRESENT_CONFIRM_MS` | `300` | OUT must stay high this long to count as an arrival |
| `LOCK_AFTER_ABSENT_MS` | `60000` | OUT must stay low this long to count as gone |
| `HEARTBEAT_MS` | `5000` | Interval of the serial status line |

The radar adds its own hold time before OUT drops. Measured here, OUT went low about 6 seconds
after leaving, so the lock lands roughly 66 seconds after walking away.

## Wiring as built

The radar's 5-pin header is soldered straight into the S2 Mini's outer row at the USB end.

| LD2410C pin | S2 Mini hole | Used by the sketch |
|---|---|---|
| VCC | VBUS (5V) | Power. The radar needs 5V, not 3V3 |
| GND | GND | Ground |
| OUT | 16 | Yes, the presence signal |
| RX | 18 | No |
| TX | 33 | No |

If UART code is added later, the radar's TX is on GPIO33 and its RX is on GPIO18.

Hardware notes:

- The radar's chips face the S2 Mini and overhang the USB-C port. Keep the gap and the tape over
  the port's metal shell.
- The cap of button 0 has broken off. The switch underneath still works and is not stuck. Uploads
  do not need it (see below).

## Toolchain

| Item | Value |
|---|---|
| arduino-cli | 1.6.0, the copy bundled with Arduino IDE. It is not on PATH |
| Path | `C:\Program Files\Arduino IDE\resources\app\lib\backend\resources\arduino-cli.exe` |
| Core | `esp32:esp32` 3.3.12 (Espressif), from the default board index |
| FQBN | `esp32:esp32:lolin_s2_mini:CDCOnBoot=default` |

`CDCOnBoot=default` means "USB CDC On Boot: Enabled", which is this board's default. Disabled
would be `CDCOnBoot=dis_cdc`, and the serial output would then not appear on the USB port.

To install the core on a fresh machine:

```powershell
$cli = "C:\Program Files\Arduino IDE\resources\app\lib\backend\resources\arduino-cli.exe"
& $cli core update-index
& $cli core install esp32:esp32
```

## Compile

Run in PowerShell. The sketch path contains a space, so keep the quotes.

```powershell
$cli    = "C:\Program Files\Arduino IDE\resources\app\lib\backend\resources\arduino-cli.exe"
$sketch = "C:\dev\Presence Monitor\PresenceWake"
$build  = "$env:TEMP\PresenceWake-build"
& $cli compile --fqbn "esp32:esp32:lolin_s2_mini:CDCOnBoot=default" --warnings all --build-path $build $sketch
```

A clean build ends with a "Sketch uses ... bytes (23%)" line and no warnings.

## Upload

Find the port first. The running board has been COM4 on this PC every time so far.

```powershell
& $cli board list
& $cli upload -p COM4 --fqbn "esp32:esp32:lolin_s2_mini:CDCOnBoot=default" --input-dir $build $sketch
```

No button press is needed. arduino-cli switches the board into upload mode by itself (it
reconnects as COM3 while flashing), then resets it back to COM4 running the new firmware. Success
is "Hash of data verified" for the app image and exit code 0.

This only works while the firmware on the board is running and showing a COM port. If a bad
build ever stops the board enumerating, force upload mode by hand: hold button 0, tap RST, release
0. The board then appears on COM3; upload to that port and press RST afterwards. With the cap
missing, press the bare switch with something non-metal.

## Watch the serial output

115200 baud. Close any other serial monitor first, since only one program can hold the port.

```powershell
$sp = New-Object System.IO.Ports.SerialPort "COM4",115200
$sp.DtrEnable = $true; $sp.RtsEnable = $true; $sp.ReadTimeout = 500
try {
  $sp.Open(); $end = (Get-Date).AddSeconds(60)
  while ((Get-Date) -lt $end) {
    try { "{0}  {1}" -f (Get-Date -Format "HH:mm:ss.fff"), $sp.ReadLine().TrimEnd() } catch [TimeoutException] {}
  }
} finally { if ($sp.IsOpen) { $sp.Close() } }
```

`DtrEnable` matters: without it the board sends nothing. Change `AddSeconds(60)` for a longer run.

Keep `RtsEnable` set to `$true`. With RTS off, closing the port left the board in upload mode
(COM3, no keyboard or mouse) both times it was tried, so the sketch stopped running until the
board was reset. The ESP32 core treats a particular DTR/RTS sequence as "restart into the
bootloader" (`_onLineState` in the core's `USBCDC.cpp`), and opening with RTS off appears to
complete it on close.

If the board is ever found on COM3 with no keyboard or mouse, this restarts it without a button
press:

```powershell
$esp = "$env:LOCALAPPDATA\Arduino15\packages\esp32\tools\esptool_py\5.3.1\esptool.exe"
& $esp --chip esp32s2 --port COM3 --after hard-reset read-mac
```

For a longer session with labelled test phases and a CSV log, use `tools\Test-PresenceWake.ps1`.
Its header comment explains the keys.

What the lines mean:

| Line | Meaning |
|---|---|
| `PresenceWake started. DRY_RUN=0 LOCK=1` | Printed once, 1.5 s after boot. Usually missed |
| `out=1 present=1 lowFor=0s` | Heartbeat every 5 s. `out` is the raw radar pin, `present` is the sketch's state |
| `[STATE] PRESENT` then `[ACTION] wake: ...` | Arrival detected, wake action sent |
| `[STATE] ABSENT` then `[ACTION] lock: Win+L` | 60 s of no presence, lock sent |

The heartbeat does not show the `DRY_RUN` value. Only the startup banner does.

## Measured behaviour

| Check | Result |
|---|---|
| Arrive to wake action | 300 ms after OUT goes high |
| Leave to lock | 60 s after OUT goes low; Windows lock screen appeared within 50 ms of the action |
| Sitting at the desk, 3 minutes | No dropouts |
| Empty room, up to 4.5 minutes | No false presence |
| Return after a lock | Screen woke with the PIN box showing |

## Not tested

- Sitting still for longer than 3 minutes. If the PC locks while you are at the desk, raise
  `LOCK_AFTER_ABSENT_MS`, or raise the radar's stationary sensitivity with the HLKRadarTool phone
  app (the LD2410C is configurable over Bluetooth).
- Behaviour across a PC restart, sleep or hibernate.
- Performance inside the finished enclosure. All captures above were taken before it was fitted,
  or without confirming it was fitted.

## Going back to dry run

Set `DRY_RUN` to `true` in the sketch, then compile and upload as above. The board then logs the
actions without sending any keys or mouse movement.
