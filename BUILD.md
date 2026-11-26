# Build guide

This guide takes you from two loose boards to a working presence monitor. Take it one step at a
time. Nothing here is hard, and there's only one spot where you need to be careful (it's flagged).

> This guide covers the electronics and the code. Enclosures and monitor mounts are coming
> separately, so for now your gadget will be "naked", which is perfect for testing anyway.

**Steps**

1. [Wire the two boards together](#1-wire-the-two-boards-together)
2. [Install the Arduino IDE](#2-install-the-arduino-ide)
3. [Load the code](#3-load-the-code)
4. [Test it safely](#4-test-it-safely)
5. [Turn it on for real](#5-turn-it-on-for-real)
6. [Make it yours (settings)](#6-make-it-yours)

Plus: [Troubleshooting](#troubleshooting), [testing tool](#optional-the-testing-tool) and
[command-line build](#optional-build-from-the-command-line).

---

## 1. Wire the two boards together

Only three wires actually matter: power, ground and the radar's "someone's here" signal. The other
two are spares for future features, but it's easiest to connect all five now.

| Radar (LD2410C) pin | S2 Mini pin | What it does |
|---|---|---|
| VCC | **VBUS** (5V) | Power. The radar needs 5V, so don't use the 3V3 pin |
| GND | **GND** | Ground |
| OUT | **16** | Goes high when someone is there. This is the one the code watches |
| TX | **33** | Spare (not used yet) |
| RX | **18** | Spare (not used yet) |

You can use short jumper wires, or solder the radar's pin header straight onto the S2 Mini so the
two boards stack into one neat little sandwich. Both work the same.

**If you stack them:**

- Leave a small gap between the boards.
- The radar's chips end up hanging over the S2 Mini's USB-C port. Put a piece of electrical or
  Kapton tape over the port's metal shell so nothing can short against it.

**This is the careful part. Double-check before you plug in:** VCC goes to VBUS and GND goes to GND. Those two are the only
ones that can cause trouble if they're swapped.

## 2. Install the Arduino IDE

The Arduino IDE is a free program that puts our code onto the S2 Mini.

1. Download and install the **Arduino IDE** (version 2) from
   [arduino.cc/en/software](https://www.arduino.cc/en/software).
2. Open it, then go to **Tools > Board > Boards Manager**.
3. Search for **esp32** and install **esp32 by Espressif Systems**. It's a big download, so grab a
   coffee.

## 3. Load the code

1. Download this project (green **Code** button on GitHub, then **Download ZIP**) and unzip it.
2. In the Arduino IDE, choose **File > Open** and open `PresenceWake/PresenceWake.ino`.
3. Plug the S2 Mini into your PC with the USB-C cable.
4. Set up the board under the **Tools** menu:
   - **Board:** esp32 > **LOLIN S2 Mini**
   - **USB CDC On Boot:** **Enabled** (this is what lets you see its messages later)
   - **Port:** the COM port that showed up when you plugged it in
5. Click **Upload** (the right-arrow button).

### The very first upload

A brand-new S2 Mini usually needs a little nudge into "upload mode" the first time:

1. Hold down the **0** button.
2. While holding it, tap the **RST** button.
3. Let go of **0**.
4. A new COM port appears. Pick it under **Tools > Port** and click **Upload**.
5. When the upload finishes, tap **RST** once to start your new code.

After that first time, you can skip all of this. Just click **Upload** and the IDE handles it.
Don't worry if the COM port number changes for a moment during an upload; that's normal.

You'll know it worked when the IDE says something like **"Hash of data verified"** and
**"Hard resetting"** at the bottom.

## 4. Test it safely

Before letting it lock your PC, it's nice to watch what it's thinking first.

**Optional but recommended: turn on dry run.** Near the top of `PresenceWake.ino`, change:

```cpp
const bool     DRY_RUN               = false;
```

to `true` and upload again. In dry run, the board reports what it *would* do but never touches
your keyboard or mouse.

Now watch it:

1. Open **Tools > Serial Monitor** and set the speed to **115200 baud**.
2. Every 5 seconds you'll see a status line like this:

   ```
   out=1 present=1 lowFor=0s
   ```

   - `out` is the radar's raw signal (1 = it sees someone).
   - `present` is what the code has decided (1 = you're here).
   - `lowFor` is how long the radar has seen nobody.

3. Walk out of the room. After about a minute you should see:

   ```
   [STATE] ABSENT
   [ACTION] lock: Win+L
   ```

4. Walk back in. Right away you should see:

   ```
   [STATE] PRESENT
   [ACTION] wake: mouse nudge + Ctrl tap
   ```

If you see all of that, everything is working.

## 5. Turn it on for real

Set `DRY_RUN` back to `false`, upload once more, and you're live:

- **Walk in:** within about a third of a second, your screen wakes and the sign-in box pops up.
- **Walk away:** your PC locks about 66 seconds later. That's the 60-second timer in the code,
  plus about 6 seconds the radar waits on its own to be sure you're really gone.

Why a mouse nudge *and* a Ctrl tap? The mouse nudge wakes a sleeping screen, but it doesn't lift
the Windows lock screen picture. A quick tap of Ctrl does, and Ctrl doesn't type anything if your
PC happens to already be unlocked.

## 6. Make it yours

All the settings live at the top of `PresenceWake.ino`. Change a number, upload, done.

| Setting | Default | What it does |
|---|---|---|
| `DRY_RUN` | `false` | `true` = watch only, never press keys or move the mouse |
| `ENABLE_LOCK_ON_LEAVE` | `true` | `false` = only wake the screen, never lock |
| `PRESENT_CONFIRM_MS` | `300` | How long (ms) the radar must see you before it counts as "arrived" |
| `LOCK_AFTER_ABSENT_MS` | `60000` | How long (ms) the room must be empty before it locks. 60000 = 1 minute |
| `HEARTBEAT_MS` | `5000` | How often (ms) the status line prints |

### Fine-tuning the radar (optional)

The LD2410C has Bluetooth built in. With the free **HLKRadarTool** app on your phone you can
adjust how far it looks and how sensitive it is. Handy if it's seeing through a wall into the
hallway, or losing you when you sit very still.

---

## Troubleshooting

**No COM port shows up when I plug it in.**
Try a different USB-C cable. Lots of cables only carry power, not data. If that's not it, use the
button trick from [the very first upload](#the-very-first-upload).

**The upload fails or times out.**
Same button trick: hold **0**, tap **RST**, let go of **0**, pick the new port, upload, then tap
**RST** when it's done.

**The Serial Monitor is blank.**
Only one program can use the COM port at a time, so close anything else that might have it open
(including the testing tool below). Check the speed is 115200 and wait at least 5 seconds for the
first status line. Also make sure **USB CDC On Boot** was set to **Enabled** when you uploaded.

**It locks my PC while I'm sitting right there.**
Raise `LOCK_AFTER_ABSENT_MS` (try `120000` for 2 minutes), or turn up the radar's stationary
sensitivity in the HLKRadarTool app.

**It thinks someone is there when the room is empty.**
Things that move, like a fan, curtains or a pet, can fool it. Lower the sensitivity or shorten the
detection range in the HLKRadarTool app, or point the radar away from the moving thing.

**It wakes the screen, but the sign-in box doesn't appear.**
Make sure `DRY_RUN` is `false`, then upload again.

### Things that haven't been tested yet

- Sitting still for longer than about 3 minutes at a time.
- What happens around a PC restart, sleep or hibernate.
- How well the radar sees through an enclosure.

If you try any of these, I'd love to hear how it goes.

---

## Optional: the testing tool

`tools/Test-PresenceWake.ps1` is a PowerShell script that watches the board, color-codes what it
sees and saves a CSV log. It can also run a little test routine and give you a pass/fail summary.

Close the Arduino Serial Monitor first, then run (swap in your own COM port):

```powershell
powershell.exe -ExecutionPolicy Bypass -File .\tools\Test-PresenceWake.ps1 -Port COM4
```

While it runs, press a number key to label what you're doing:

| Key | Test | What to do |
|---|---|---|
| 1 | walk-in | Walk into the room |
| 2 | sit-still | Sit and work normally for 2 to 3 minutes |
| 3 | leave | Leave and stay out at least 90 seconds |
| 4 | empty-room | Press it on your way out, then stay away 5+ minutes |
| 0 | none | Clear the label |
| q | quit | Stop and show the summary |

The log files are saved next to the script. They record when you were at your desk, so they're
kept out of Git on purpose.

## Optional: build from the command line

If you'd rather skip the IDE window, the same build works with `arduino-cli`. A copy comes with the
Arduino IDE, or you can install it on its own. Run these in PowerShell from the project folder:

```powershell
# Point this at your arduino-cli. This is where the Arduino IDE keeps its copy:
$cli  = "C:\Program Files\Arduino IDE\resources\app\lib\backend\resources\arduino-cli.exe"
$fqbn = "esp32:esp32:lolin_s2_mini:CDCOnBoot=default"

# One time: install ESP32 support
& $cli core update-index
& $cli core install esp32:esp32

# Find your port
& $cli board list

# Build and upload in one go (change COM4 to your port)
& $cli compile --fqbn $fqbn --upload -p COM4 .\PresenceWake
```

`CDCOnBoot=default` is the same as **USB CDC On Boot: Enabled** in the IDE.
