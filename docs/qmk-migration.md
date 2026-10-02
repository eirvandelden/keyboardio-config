# Switching the Model 100 to QMK

This guide covers three things: how to put QMK on the Model 100, how to carry the current Chrysalis layout over, and which QMK features are worth opting into.

Written 2026-09-25, updated 2026-10-01. The keymap in `keyboards/keyboardio/model100/keymaps/eirvandelden/keymap.c` compiles against the pinned QMK commit, and `bin/keymap-parity` finds no difference from `Chrysalis_Keyboardio-Model-100_layout.json` apart from the two accepted exceptions. Nothing has been flashed yet.

## Where QMK support stands

- Pull request: [qmk/qmk_firmware#26397](https://github.com/qmk/qmk_firmware/pull/26397), "[Keyboard] Add Keyboardio Model 100", by Daniel Shields (`shieldsd`).
- State on 2026-09-25: open, approved by a QMK collaborator (`drashna`), targets `master`, last updated 2026-08-16. Not merged yet.
- The author reports daily-driving it on their own Model 100 ([forum post](https://community.keyboard.io/t/trying-to-reach-the-support-line-at-support-keyboard-io/13875/12)).
- Until it merges, the keyboard only exists on the branch `keyboardio-model100-pr` of `shieldsd/qmk_firmware`.

What the port supports, from its readme:

- The full 64-key matrix over the same I2C protocol as Kaleidoscope.
- Mouse keys, media keys, per-key RGB (`rgb_matrix`) on both halves.
- Settings in flash-emulated EEPROM.

What it does not support:

- Mouse warping (`Key_mouseWarp*`). QMK has no absolute mouse positioning. My live layout does not use it.
- Software entry into the bootloader via `QK_BOOT` is not reliable. Holding `Prog` while plugging in is.
- LED gamma correction and the fast batch LED update.

The bootloader (Keyboardio's DAPBoot) stays untouched. QMK is flashed after it, at `0x08002000`, the same way Kaleidoscope is. The readme states the Model 100 is very hard to brick short of overwriting that bootloader, so going back to Kaleidoscope stays possible.

## What I lose by leaving Kaleidoscope

- Chrysalis. It speaks Kaleidoscope's Focus protocol, which QMK does not implement. The keymap moves into a C file in this repository. That matches how this repository already works, since the layout JSON is committed here anyway.
- My opposite-hands change to Qukeys ([keyboardio/Kaleidoscope#1539](https://github.com/keyboardio/Kaleidoscope/pull/1539)) and the fork that carries it. QMK has the same behaviour built in as Chordal Hold. See below.
- The availability light plugin. It is shelved and not flashed, so nothing is lost today. QMK's Raw HID could carry the same idea later.

## Step 1: prepare a way back

Do this before flashing QMK.

1. Build the current Kaleidoscope firmware and keep the `.bin` outside this repository. Build it from commit `1ee038c` of this repository (the last one before the availability light, which was never flashed), against my fork at `~/Developer/Kaleidoscope`, in the Arduino IDE. Suggested place for the file: `~/Documents/keyboardio/model100-kaleidoscope-1ee038c.bin`. It was not built yet on 2026-10-01. Build it before the first QMK flash.
2. Confirm `Chrysalis_Keyboardio-Model-100_layout.json` in this repository matches what is on the keyboard. Export again from Chrysalis if in doubt, and commit it.
3. Expect the saved settings area to be overwritten. QMK and Kaleidoscope both keep settings in the same flash. After going back, import the layout JSON in Chrysalis again.

Going back: hold `Prog`, plug in, and flash the kept `.bin` with `dfu-util -d 3496:0005 -a 0 -R -D ~/Documents/keyboardio/model100-kaleidoscope-1ee038c.bin` (the command QMK runs in step 4), or upload from the Arduino IDE as before. Then import `Chrysalis_Keyboardio-Model-100_layout.json` in Chrysalis, which restores the settings area QMK overwrote.

## Step 2: install the QMK tools

- QMK CLI: `brew install qmk/qmk/qmk`. It brings the ARM compiler and `dfu-util`.
- Check afterwards with `qmk doctor`.
- Homebrew installs both compilers keg-only, so `qmk doctor` reports `arm-none-eabi-gcc` and `avr-gcc` as missing, and `qmk compile` fails with `arm-none-eabi-gcc: command not found`. Builds work with them on `PATH`: `export PATH=/opt/homebrew/opt/arm-none-eabi-gcc@8/bin:/opt/homebrew/opt/arm-none-eabi-binutils/bin:$PATH`. `qmk c2json` and `qmk info` need no compiler.

## Step 3: get the Model 100 into a QMK checkout

Until the pull request merges, use the author's branch through my fork `eirvandelden/qmk_firmware`, so a force-push to `shieldsd` cannot change my builds:

```sh
git clone --recurse-submodules -b keyboardio-model100-pr \
  https://github.com/eirvandelden/qmk_firmware.git ~/Developer/qmk_firmware
git -C ~/Developer/qmk_firmware remote add shieldsd https://github.com/shieldsd/qmk_firmware.git
qmk config user.qmk_home="$HOME/Developer/qmk_firmware"
qmk compile -kb keyboardio/model100 -km default
```

The last command builds the port's own default keymap. If it builds, the tools work. It built on 2026-10-01.

Pinned QMK commit: `2c745388201b633ba04036b17157669632d1740a` (2026-08-15, "[Keyboard] Add Keyboardio Model 100"). A rebuild months later checks that commit out first. To take newer work from the author, fetch the `shieldsd` remote and move the pin on purpose.

Once the pull request merges, point `user.qmk_home` at an upstream clone instead (`qmk setup`).

## Step 4: first flash with the default keymap

Flash the untouched default keymap first. That separates "does the port work on my keyboard" from "did I convert my layout correctly".

1. Unplug the keyboard. Hold `Prog` (top left). Plug it in. The keyboard now shows up as `3496:0005`.
2. Run `qmk flash -kb keyboardio/model100 -km default`. According to the port's `rules.mk`, that runs `dfu-util -d 3496:0005 -a 0 -R -D <firmware>.bin`.
3. Type on it for a while. The keyboard shows up as `3496:0006` when it is running.

Things to check: every key registers, including the palm keys and both inner columns. The LEDs light on both halves. There are no doubled letters. Doubled letters were the reason for `setKeyscanInterval(2)` with my third-party switches.

## Step 5: keep my keymap in this repository

QMK's external userspace lets a keymap live outside the QMK checkout. This repository becomes that userspace:

```
qmk.json
keyboards/keyboardio/model100/keymaps/eirvandelden/
  keymap.c
  config.h
  rules.mk
```

Set it up once:

```sh
qmk config user.overlay_dir="$HOME/Developer/keyboardio-config"
qmk userspace-add -kb keyboardio/model100 -km eirvandelden
qmk compile -kb keyboardio/model100 -km eirvandelden
```

QMK only detects a userspace that already has a valid `qmk.json`, so `qmk.json` was first written by hand (`userspace_version` and empty `build_targets`), and `qmk userspace-add` then added the target.

The overlay is combined with the QMK checkout from `user.qmk_home`, so it works with the author's branch. QMK's GitHub Actions template for userspace builds against upstream `master`. It will not find the Model 100 until the pull request merges.

## Converting the Chrysalis layout

### What is actually on the keyboard

The keyboard runs the Chrysalis layout, not the keymap in `Model100.ino` (`keymap.onlyCustom = true`). Four layers are in use:

| Kaleidoscope layer | Reached by | Contents | QMK layer |
|---|---|---|---|
| 0 | default | Dvorak letters, mods on the top letter row, media keys on the right inner column | `BASE` (0) |
| 1 | hold left palm key, or `LockLayer(1)` top right | numbers with mods, `! @ # $ % ^ & * ( )` | `NUMBERS` (1) |
| 2 | hold right palm key | arrows, Home/End/PgUp/PgDn, Insert, Caps Lock, plain mods on the left | `NAVIGATION` (2) |
| 4 | hold both palm keys | LED controls, volume, track, screen brightness, mute | `MEDIA` (3) |

Layers 3, 5, 6 and 7 are empty.

### Dvorak on the Mac

The Mac does Dvorak in software. The keyboard sends QWERTY positions. QMK ships `keymap_dvorak.h`, whose `DV_*` names map a Dvorak character to the QWERTY position that produces it. `DV_S` is `KC_SCLN`, for example. Using those names lets the keymap read as Dvorak while sending the same codes Chrysalis sends today. `Ctrl+S` on the left inner key becomes `LCTL(DV_S)`.

### How each kind of key translates

| Kaleidoscope / Chrysalis | QMK |
|---|---|
| plain key | `DV_*` or `KC_*` |
| key with modifier, such as `Shift+9` | `DV_LPRN`, `LCTL(DV_S)` |
| Qukeys dual-use modifier (`DUM`) | mod-tap: `LCTL_T(DV_QUOT)` and so on |
| `ShiftToLayer(n)` | `MO(n)` |
| `LockLayer(n)` | `TG(n)` |
| media and brightness keys | `KC_MPRV`, `KC_MPLY`, `KC_MNXT`, `KC_MUTE`, `KC_VOLD`, `KC_VOLU`, `KC_BRID`, `KC_BRIU` |
| `LEDEffectNext`, `Previous`, `Toggle` | `RM_NEXT`, `RM_PREV`, `RM_TOGG` |
| transparent | `_______` on upper layers, `XXXXXXX` (nothing) on the base layer |

Key positions do not carry over by number. Kaleidoscope's left hand runs `r0c0`–`r3c7` and the right `r0c8`–`r3c15`. QMK's matrix is 8×8 with the columns mirrored: left `[row][7 - col]`, right `[row + 4][15 - col]`. QMK's `LAYOUT()` macro then lists keys in physical order. The inner-column keys (LED/Any, Tab/Enter, the lower "butterfly" keys) sit in the middle of rows 1–3, as the 7th and 8th of each row's 14 keys, between the two halves. The thumb keys come last, alternating left and right, then the two palm keys.

### Keys that need a decision

- **Top-left `Prog` key**: transparent in Chrysalis, so `XXXXXXX` here. Holding it while plugging in still starts the bootloader. That is handled by the bootloader, not the keymap.
- **Left inner middle key**: Chrysalis sends consumer usage `0x2A2` and labels it "Mission Control". QMK's `KC_MCTL` sends `0x29F` ("show all windows"). Try `KC_MCTL` first. If the Mac does something different from today, send `0x2A2` from `process_record_user` with `host_consumer_send(0x2A2)`.
- **Both-palms layer**: done here as `MO(MEDIA)` on the opposite palm key of layers 1 and 2, as in Chrysalis. QMK's Tri Layer feature (`TRI_LAYER_ENABLE = yes`, `TL_LOWR`/`TL_UPPR`) does the same thing without the extra keys.
- **The `LEDEffect` toggle appears twice** on the media layer (`r1c12`, `r1c13`). Copied as is.
- **Mod-tap tap keys must be basic keycodes.** Every dual-use key in my layout already is.

### The keymap

The keymap is `keyboards/keyboardio/model100/keymaps/eirvandelden/keymap.c`. It started as a script-generated draft, and `bin/keymap-parity` found no difference from the Chrysalis export. That file is the one copy of the keymap. Its `LAYOUT` grids follow the port's physical key order.

`bin/keymap-parity` reads the Chrysalis JSON, runs `qmk c2json --no-cpp` and `qmk info`, and lists every key whose meaning differs. Two differences are accepted: the Mission Control key (`KC_MCTL` instead of `0x2A2`) and transparent keys on the base layer (no key). It can be removed together with Chrysalis.

## Dual-use timing

The keymap uses QMK's default timing plus three features. This was a choice on 2026-09-30, instead of porting the Qukeys values. The keymap's `config.h` holds exactly this:

```c
#define PERMISSIVE_HOLD
#define CHORDAL_HOLD
#define FLOW_TAP_TERM 150
```

At the pinned commit `TAPPING_TERM` is 200 ms and `QUICK_TAP_TERM` equals it. Permissive Hold makes a mod-tap a hold when another key is pressed and released inside it. QMK's documentation says Chordal Hold is meant to be used with Permissive Hold or Hold On Other Key Press, and without one of them it adds nothing for opposite-hand chords. Flow Tap at 150 ms (the value QMK's documentation suggests) keeps top-row modifiers from firing while typing. Flow Tap is not a copy of the Qukeys minimum prior interval: its default filter skips digits, grave and brackets, and it is off during some modifier chords and while a tap-hold is undecided.

The Qukeys values in `Model100.ino`, kept for reference:

| Kaleidoscope | Value | Used in QMK |
|---|---|---|
| `setHoldTimeout` | 250 | no, QMK default `TAPPING_TERM` (200) |
| `setEnableOppositeHandsRule(true)` | on | `CHORDAL_HOLD` |
| `setMinimumPriorInterval` | 150 | `FLOW_TAP_TERM 150` |
| `setOverlapThreshold` | 60% | `PERMISSIVE_HOLD`, nearest, not identical |
| `setMinimumHoldTime` | 100 | none |
| `setMaxIntervalForTapRepeat` | 300 | no, QMK default `QUICK_TAP_TERM` (200) |
| `setKeyscanInterval(2)` | 2 ms | the port already sets the scanner chips' interval to 2 in `matrix.c` (`matrix_init_custom()`) |

`"debounce": 0` in the port's `keyboard.json` is a separate QMK setting and stays. If doubled letters appear, try `#define DEBOUNCE 5` with `DEBOUNCE_TYPE = sym_eager_pk` in `rules.mk`, and record the doubled letters as a finding in `docs/changes/8-move-the-model-100-to-qmk-firmware/keyboard-checklist.md`.

## Opposite-hands rule: Chordal Hold

My Kaleidoscope pull request makes a Qukeys key resolve as a tap when the next key is on the same hand, deciding hand by column. QMK's Chordal Hold does the same: a mod-tap followed by a key on the same hand settles as a tap, and on the opposite hand it can become a hold. The hold timeout still applies either way, which keeps `Ctrl` + mouse click working.

QMK needs to know which half each key is on. The keymap answers with a callback instead of a hand-typed 64-entry table, which would have to follow `LAYOUT()` order:

```c
char chordal_hold_handedness(keypos_t key) {
  return key.row < MATRIX_ROWS / 2 ? 'L' : 'R';
}
```

Matrix rows 0–3 are the left half and rows 4–7 the right half, the same split as Kaleidoscope columns 0–7 against 8–15, thumbs and palm keys included. Returning `'*'` for a key lets it chord with either hand. That is worth trying for the thumb and palm keys, so a left mod plus left-thumb `Enter` or `Tab` still counts as a hold. Kaleidoscope's version could not do this.

After `TAPPING_TERM` (200 ms), Chordal Hold no longer stops a hold, so a slow same-hand chord is a hold.

## Worth opting into later

Grouped by the problem each one solves. Each is off unless enabled.

Typing accuracy with top-row mods:

- **Chordal Hold**, **Permissive Hold** and **Flow Tap** are already on, as above. They replace most of the Qukeys tuning.
- **Per-key tapping term** (`TAPPING_TERM_PER_KEY`, `get_tapping_term()`): a longer term for the ring and little finger mods only.
- **Speculative Hold** (`SPECULATIVE_HOLD`): sends the modifier on key down, so Cmd+click and Shift+click feel instant.

Fewer keys, more reach:

- **Combos**: two keys pressed together send a third. Useful for `Esc`, brackets, or `Ctrl+S` without a dedicated key.
- **Tap Dance**: one key, different output on single or double tap.
- **Key Overrides**: change what `Shift` + a key sends.
- **Leader key**: a key followed by a short sequence triggers an action.
- **Layer Lock**: lock whatever layer is held.
- **Repeat Key**: a key that repeats the previous key.

Caps Word and Autocorrect are left out of the first switch. They need extra work because of software Dvorak. See [Features that read key codes as letters](#features-that-read-key-codes-as-letters).

Lights:

- **Per-layer colours**: my Chrysalis colormap (red, blue, yellow, green on black, per layer) becomes code in `rgb_matrix_indicators_advanced_user()`. It has not been converted here. The order Chrysalis stores colours in has not been mapped to the port's `rgb_matrix` LED order yet, and that mapping has to be checked on the keyboard.
- **Idle timeout**: `#define RGB_MATRIX_TIMEOUT 900000` replaces IdleLEDs' 900 seconds.
- **Sleep with the computer**: `#define RGB_MATRIX_SLEEP` replaces the `HostPowerManagement` handler.

Talking to the computer:

- **Raw HID** (`RAW_ENABLE = yes`): a direct channel between a computer program and the keyboard. This is where the shelved availability light would go.

## Features that read key codes as letters

The keyboard does not know the Mac uses Dvorak. It sends the code for a physical position, named after the QWERTY letter there, and macOS turns that into a Dvorak letter. Features that run on the keyboard and look at letters see the QWERTY name, not the letter I see.

Neither Caps Word nor Autocorrect is enabled on the first switch to QMK. This section records what each would need.

### Caps Word

Caps Word types capitals until the end of the word. QMK's default `caps_word_press_user()` shifts and continues on `KC_A`–`KC_Z` and `KC_MINS`, continues without shift on digits, `KC_BSPC`, `KC_DEL` and `KC_UNDS`, and ends on anything else. Under software Dvorak:

| I type | Key code sent | Default Caps Word | Result |
|---|---|---|---|
| `s`, `w`, `v`, `z` | `KC_SCLN`, `KC_COMM`, `KC_DOT`, `KC_SLSH` | ends the word | `MAX_RETRIES` becomes `MAX_RETRIEs` |
| `'` `,` `.` `;` | `KC_Q`, `KC_W`, `KC_E`, `KC_Z` | shifts them | `,` becomes `<`, `.` becomes `>` |
| `-` | `KC_QUOT` | ends the word | `FOO-BAR` stops after `FOO` |

To enable it later, add `CAPS_WORD_ENABLE = yes` to `rules.mk` and override the rule with Dvorak names:

```c
bool caps_word_press_user(uint16_t keycode) {
    switch (keycode) {
        case DV_A: case DV_B: case DV_C: case DV_D: case DV_E: case DV_F:
        case DV_G: case DV_H: case DV_I: case DV_J: case DV_K: case DV_L:
        case DV_M: case DV_N: case DV_O: case DV_P: case DV_Q: case DV_R:
        case DV_S: case DV_T: case DV_U: case DV_V: case DV_W: case DV_X:
        case DV_Y: case DV_Z:
            add_weak_mods(MOD_BIT(KC_LSFT));
            return true;
        case KC_1 ... KC_0:
        case KC_BSPC:
        case KC_DEL:
        case DV_MINS:
        case DV_UNDS:
            return true;
        default:
            return false;
    }
}
```

This keeps `-` unshifted inside a word. Moving `DV_MINS` into the shifted group turns `-` into `_` instead.

A way to turn it on is also needed: a key (`CW_TOGG`) or `#define BOTH_SHIFTS_TURNS_ON_CAPS_WORD`.

### Autocorrect

Autocorrect keeps a list of recent keys and compares it with a list of typos built into the firmware. On a match it sends backspaces and the correct letters. Three things break under software Dvorak:

1. The typo list is converted to QWERTY key codes. `teh -> the` watches for `KC_T KC_E KC_H`, which I type as `y.d`, and replaces it with what the Mac shows as `yd.`. The list would have to be translated into QWERTY positions first.
2. Only `KC_A`–`KC_Z` count as letters. My `s`, `w`, `v` and `z` send punctuation codes and count as word breaks, so no typo containing them can ever match.
3. My `'` `,` `.` `;` send letter codes, so a comma after a word does not end the word.

`process_autocorrect_user()` can redefine which keys count as letters, which fixes points 2 and 3. With point 1 as well, that means keeping a custom version of the feature. The simpler choice is macOS's own spelling correction, which works after the Dvorak translation and sees real letters.

### Other features that care

- **Leader key** sequences are key codes: write `DV_S`, not `KC_S`.
- **Typed text** (`SEND_STRING`) goes through a QWERTY table by default, so `SEND_STRING("hello")` shows up as `d.nnr`. Add `#include "sendstring_dvorak.h"` to the keymap before using it.
- Combos, Tap Dance, Key Overrides, Chordal Hold and Flow Tap only deal with positions and are not affected.

## Proposed order of work

1. Step 1: keep a way back.
2. Steps 2–4: tools, the author's branch, flash the default keymap, and type on it.
3. Step 5: the userspace files, keymap and timing settings are in this repository and compile (done 2026-10-01). Flash with `qmk flash -kb keyboardio/model100 -km eirvandelden`.
4. Work through `docs/changes/8-move-the-model-100-to-qmk-firmware/keyboard-checklist.md` and compare against the Kaleidoscope feel.
5. Per-layer colours, then anything from the opt-in list.
6. When the pull request merges, move `user.qmk_home` to upstream QMK and retire the `Model100/` sketch and the Kaleidoscope fork.
