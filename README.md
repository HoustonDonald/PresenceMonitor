# PresenceMonitor

A small USB device that locks a Windows PC when you walk away and wakes it when you come back.

A LOLIN S2 Mini (ESP32-S2) reads an HLK-LD2410C 24 GHz presence radar and acts as a USB keyboard
and mouse:

- **You leave:** after 60 seconds with nobody in view, it sends Win+L.
- **You arrive:** it nudges the mouse to wake the display, then taps Left Ctrl to lift the lock
  screen cover so the PIN box is ready.

It never types a password. Unlocking is still Windows Hello or your PIN.

## Contents

| Path | What it is |
|---|---|
| `PresenceWake/PresenceWake.ino` | The Arduino sketch |
| `PresenceWake/BUILD.md` | Wiring, toolchain, compile, upload, serial output and measured behaviour |
| `tools/Test-PresenceWake.ps1` | PowerShell serial monitor that logs labelled test phases to CSV |
| `mount/` | OpenSCAD sources, STL files and preview images for the enclosure and mounts |

Start with [PresenceWake/BUILD.md](PresenceWake/BUILD.md).

## Licence

MIT. See [LICENSE](LICENSE).
