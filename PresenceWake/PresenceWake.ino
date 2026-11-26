/*
  PresenceWake - LOLIN S2 Mini (ESP32-S2) + HLK-LD2410C 24 GHz presence radar

  The S2 Mini plugs into the PC by USB-C and shows up as a USB keyboard + mouse.
    - Someone enters the room  -> 1-pixel mouse nudge (wakes the display), then a
                                  Left Ctrl tap (lifts the lock screen cover)
    - Room empty for LOCK_AFTER_ABSENT_MS -> Win+L (lock on leave), optional

  It never types a password. Unlock is Windows Hello (face, fingerprint, or PIN).

  Wiring (LD2410C -> S2 Mini):
    VCC -> VBUS (5V)      the radar needs 5V; the 3V3 pin is not enough
    GND -> GND
    OUT -> GPIO16         3.3V logic, safe for the ESP32-S2
    TX  -> GPIO33         unused by this sketch; only needed for UART config/distance later
    RX  -> GPIO18         unused by this sketch
  As built, the radar's 5-pin header is soldered straight into the outer row, which is
  what puts TX and RX on 33 and 18.

  Arduino IDE: board "LOLIN S2 Mini" (esp32 by Espressif), USB CDC On Boot: Enabled.
  Full build steps, including the first-upload button trick, are in BUILD.md at the repo root.
*/

#include "USB.h"
#include "USBHIDMouse.h"
#include "USBHIDKeyboard.h"

USBHIDMouse Mouse;
USBHIDKeyboard Keyboard;

// ---- Settings ----------------------------------------------------------------
const bool     DRY_RUN               = false;    // true = log only, no mouse/keyboard. Handy for testing.
const bool     ENABLE_LOCK_ON_LEAVE  = true;     // send Win+L after the room is empty
const uint32_t PRESENT_CONFIRM_MS    = 300;      // OUT must stay high this long before we call it "arrived"
const uint32_t LOCK_AFTER_ABSENT_MS  = 60000;    // OUT low this long = "left" (sensor adds its own hold time on top)
const uint32_t HEARTBEAT_MS          = 5000;     // serial status line interval

const int PIN_RADAR_OUT = 16;
const int PIN_LED       = 15;                    // S2 Mini onboard blue LED

// ---- State -------------------------------------------------------------------
bool     present    = false;
uint32_t highSince  = 0;
uint32_t lowSince   = 0;
uint32_t lastBeat   = 0;

void wakeScreen() {
  Serial.println("[ACTION] wake: mouse nudge + Ctrl tap");
  if (DRY_RUN) return;
  Mouse.move(1, 0);
  delay(20);
  Mouse.move(-1, 0);
  // A mouse move wakes the display but does not lift the lock screen cover.
  // A lone Ctrl tap does, and types nothing if the PC happens to be unlocked.
  delay(100);
  Keyboard.press(KEY_LEFT_CTRL);
  delay(50);
  Keyboard.releaseAll();
}

void lockScreen() {
  Serial.println("[ACTION] lock: Win+L");
  if (DRY_RUN || !ENABLE_LOCK_ON_LEAVE) return;
  Keyboard.press(KEY_LEFT_GUI);
  Keyboard.press('l');
  delay(50);
  Keyboard.releaseAll();
}

void setup() {
  pinMode(PIN_RADAR_OUT, INPUT_PULLDOWN);
  pinMode(PIN_LED, OUTPUT);
  digitalWrite(PIN_LED, LOW);

  Mouse.begin();
  Keyboard.begin();
  USB.begin();
  Serial.begin(115200);

  delay(1500);
  Serial.printf("PresenceWake started. DRY_RUN=%d LOCK=%d\n", DRY_RUN, ENABLE_LOCK_ON_LEAVE);
}

void loop() {
  const uint32_t now = millis();
  const bool raw = digitalRead(PIN_RADAR_OUT) == HIGH;

  if (raw) {
    lowSince = 0;
    if (highSince == 0) highSince = now;
    if (!present && now - highSince >= PRESENT_CONFIRM_MS) {
      present = true;
      digitalWrite(PIN_LED, HIGH);
      Serial.println("[STATE] PRESENT");
      wakeScreen();
    }
  } else {
    highSince = 0;
    if (lowSince == 0) lowSince = now;
    if (present && now - lowSince >= LOCK_AFTER_ABSENT_MS) {
      present = false;
      digitalWrite(PIN_LED, LOW);
      Serial.println("[STATE] ABSENT");
      lockScreen();
    }
  }

  if (now - lastBeat >= HEARTBEAT_MS) {
    lastBeat = now;
    Serial.printf("out=%d present=%d lowFor=%lus\n", raw, present,
                  lowSince ? (unsigned long)((now - lowSince) / 1000) : 0UL);
  }

  delay(20);
}
