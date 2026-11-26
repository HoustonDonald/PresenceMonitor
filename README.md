# PresenceMonitor

A tiny USB gadget that notices when you sit down at your desk and when you walk away.

- **Walk in:** it wakes your screen and pulls up the Windows sign-in box, ready for your PIN or face.
- **Walk away:** after about a minute with nobody around, it locks your PC for you.

It uses a small 24 GHz radar instead of a regular motion sensor, so it can tell you're still there
even when you're sitting perfectly still, reading or thinking. No more screen going dark mid-thought.

It never types your password. Signing back in is still up to you (PIN, Windows Hello face or
fingerprint).

## What you'll need

| Part | Notes |
|---|---|
| LOLIN S2 Mini (ESP32-S2) | The brains. It plugs into your PC and acts like a keyboard and mouse |
| HLK-LD2410C radar module | The eyes. A 24 GHz presence sensor, about the size of a postage stamp |
| USB-C cable | Must be a data cable, not a charge-only one |
| 5 short wires or a pin header | To connect the two boards |
| Soldering iron and solder | The boards come without pins attached |
| A Windows PC | The lock shortcut (Win+L) is a Windows thing |

Optional: the free **HLKRadarTool** phone app, if you want to fine-tune the radar later.

## Ready to build?

Head over to **[BUILD.md](BUILD.md)**. It walks you through wiring, loading the code and testing,
one step at a time. Plan on about an hour, most of it waiting on software to install.

## What's in here

| Path | What it is |
|---|---|
| [BUILD.md](BUILD.md) | Step-by-step build guide (start here) |
| [PresenceWake/PresenceWake.ino](PresenceWake/PresenceWake.ino) | The code that runs on the S2 Mini |
| [tools/Test-PresenceWake.ps1](tools/Test-PresenceWake.ps1) | Optional PowerShell tool for testing and logging |
| `mount/` | Enclosure and monitor mount files (work in progress, better ones coming soon) |

## License

MIT. Use it, change it, share it. See [LICENSE](LICENSE).
