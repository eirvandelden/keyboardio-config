# Spec: Move the Model 100 to QMK firmware

From `intent.md` (2026-09-29). Status: accepted.

## Flagged concerns

- **QMK is a new dependency.** The playbook asks for approval before adding one. The accepted intent is the move to QMK itself, so this spec treats QMK as approved. It adds nothing else: no Python packages, no QMK community modules. The pinned QMK source is `shieldsd/qmk_firmware@keyboardio-model100-pr`.
- **"Today's feel" versus "no Flow Tap tuning".** The intent keeps the dual-use timing as it is and leaves Flow Tap tuning for later. Kaleidoscope's minimum prior interval (150 ms) has one exact QMK counterpart, `FLOW_TAP_TERM 150`. This spec switches it on at 150 as a translation of today's setting, and leaves any change to the value for later.
- **Two Qukeys settings have no QMK counterpart.** The minimum hold time (100 ms) and the overlap threshold (60%) cannot be copied. The overlap threshold's nearest match is Permissive Hold, which is not the same rule. The week of daily use is the test for whether the feel still holds.
- **Doubled letters.** `setKeyscanInterval(2)` was added against doubled letters from my third-party switches. The QMK port reads the matrix from the scanner chips with `debounce: 0`. There is no one-to-one setting. This spec keeps the port's default and treats doubled letters during the week as a finding to fix, not a reason to guess a value now.
- **Lights differ from today.** LED work is out of this change, so the lights keep the port's defaults: a rainbow moving across the keyboard at half brightness, always on. Today's rainbow trail on key press, the per-layer colours, and lights turning off when idle or when the Mac sleeps all move to [#11](https://github.com/eirvandelden/keyboardio-config/issues/11). Until then the lights stay on while the Mac sleeps.

## Requirements

### Build

1. The QMK keymap lives in this repository as a QMK external userspace: `qmk.json` at the root and `keyboards/keyboardio/model100/keymaps/eirvandelden/` holding `keymap.c`, `config.h` and `rules.mk`.
2. The firmware builds on my machine with `qmk compile -kb keyboardio/model100 -km eirvandelden`, against one recorded commit of `shieldsd/qmk_firmware@keyboardio-model100-pr`.
3. The existing Kaleidoscope sketches (`Model01/`, `Model100/`) and `Chrysalis_Keyboardio-Model-100_layout.json` stay untouched.

### Keys

4. The keymap has four layers in this order: base, numbers (Kaleidoscope layer 1), navigation (layer 2), media (layer 4).
5. Every key on every layer sends what the Chrysalis layout sends today, key for key, with these exceptions only:
   - The Mission Control key sends `KC_MCTL` (`0x29F`) instead of `0x2A2`.
   - Transparent keys on the base layer send nothing.
6. Keys are written with QMK's Dvorak names (`DV_*`), because the Mac does Dvorak in software. The codes sent are the same QWERTY positions Chrysalis sends.
7. Holding the left palm key gives numbers, holding the right palm key gives navigation, holding both gives media. The top-right key locks and unlocks the numbers layer.

### Dual-use modifiers

8. The eight top-row dual-use keys on the base layer, and their counterparts on the numbers and navigation layers, tap as their letter or symbol and hold as their modifier, as in Chrysalis.
9. Timing: `TAPPING_TERM 250`, `PERMISSIVE_HOLD`, `QUICK_TAP_TERM 250`, `FLOW_TAP_TERM 150`.
10. Chordal Hold is on. The left half (Kaleidoscope columns 0–7, thumbs and palm key included) is `L`, the right half is `R`.

### Lights

11. The lights keep the QMK port's defaults. The LED keys in the keymap send QMK's light keys (`RM_NEXT`, `RM_PREV`, `RM_TOGG`) at the positions Chrysalis has its LED keys.

### Way back

12. A Kaleidoscope firmware file matching what is on the keyboard today is built and kept outside the repository before the first QMK flash. It is built from commit `1ee038c` (the last one before the availability light, which was never flashed), against the Kaleidoscope fork.
13. `docs/qmk-migration.md` describes going back: flash that file from the bootloader, then import `Chrysalis_Keyboardio-Model-100_layout.json` in Chrysalis.

### Left out on purpose

14. Not carried over, because the live layout does not use them or they are off: mouse keys, macros, dynamic macros, one-shot keys, SpaceCadet, magic combos (NKRO toggle, hardware test, keymap source), steno, the boot greeting, and all light behaviour beyond the port's defaults (see requirement 11).
15. Caps Word and Autocorrect stay off.

## Design decisions

- **This repository is the userspace root.** `qmk.json` and `keyboards/` sit next to `Model100/`. One repository keeps holding everything about the keyboard, and the Kaleidoscope files can be removed later without moving the QMK files.
- **QMK source is pinned to a commit, not a branch.** The port's branch can be force-pushed while its pull request is open. The commit is written down in `docs/qmk-migration.md`, so a rebuild months later produces the same firmware.
- **The keymap is written by hand, starting from the generated draft** in `docs/qmk-migration.md`. Chrysalis is being retired, so the JSON is not a long-term source to generate from.
- **Key parity is checked by a script, once.** A script compares the QMK keymap (read with `qmk c2json`) against `Chrysalis_Keyboardio-Model-100_layout.json` and lists every key that differs, apart from the two exceptions in requirement 5. It uses only Python's standard library and the QMK CLI, both already present once QMK is installed. It is the automated acceptance test for requirement 5. It can be removed with Chrysalis later.
- **Media layer numbering.** Kaleidoscope layer 4 becomes QMK layer 3. Layers 3, 5, 6 and 7 are empty in Chrysalis and are dropped.
- **Both-palms layer** stays as in Chrysalis: the opposite palm key on the numbers and navigation layers holds the media layer. QMK's Tri Layer feature would change which key does what, so it waits.
- **Prog key** sends nothing, as in Chrysalis. The bootloader still starts when it is held while plugging in, because the bootloader checks it, not the keymap.

## Integration points

- `shieldsd/qmk_firmware`, branch `keyboardio-model100-pr`, cloned locally and set as `user.qmk_home`. Later upstream `qmk/qmk_firmware` once qmk/qmk_firmware#26397 merges.
- QMK CLI on my Mac: `qmk compile`, `qmk flash`, `qmk c2json`, `qmk config user.overlay_dir`, `qmk userspace-add`.
- `dfu-util` and Keyboardio's DAPBoot bootloader (`3496:0005`), used unchanged for flashing both QMK and Kaleidoscope.
- macOS with Dvorak in software, which translates the key positions.
- The Kaleidoscope fork at `~/Developer/Kaleidoscope` and the Arduino build, for the way-back firmware.
- `Chrysalis_Keyboardio-Model-100_layout.json`, read by the parity script.

## Acceptance criteria

Automated, run on my machine:

1. The firmware for keymap `eirvandelden` compiles against the recorded QMK commit. (Requirements 1, 2, 6.)
2. The parity script reports that every key on the base, numbers, navigation and media layers matches the Chrysalis layout, apart from the Mission Control key and the base-layer transparent keys. (Requirements 4, 5.)
3. The Kaleidoscope sketches and the Chrysalis layout file are unchanged compared with `main`. (Requirement 3.)

On the keyboard, checked by me and ticked off in a checklist in the change folder:

4. Each key on each layer types what the Chrysalis layout says, checked once. (Requirements 5, 7, success criterion from the intent.)
5. Holding the right palm key and pressing the right arrow key moves the cursor right. Holding both palm keys and pressing volume up raises the volume. (Requirement 7.)
6. Tapping the top-row key in the `p` position types `p`. Holding it and tapping `h` on the other hand types capital `H`. (Requirement 8.)
7. Holding the `p`/Shift key and tapping `u` on the same hand types `pu`, not `U`. (Requirement 10.)
8. Typing `people` at normal speed never triggers a modifier from the top-row keys. (Requirement 9.)
9. Pressing the LED "next" key changes the light effect, and the LED toggle key turns the lights off and on. (Requirement 11.)
10. Flashing the kept Kaleidoscope file and importing the Chrysalis layout gives back today's keyboard, tried once. After that, QMK is flashed again. (Requirements 12, 13.)
11. I type on QMK for a week of normal work without a reason to go back. (Intent success criterion; covers the flagged timing and doubled-letter concerns.)
12. The keymap has no Caps Word or Autocorrect key, and neither feature is enabled in `rules.mk`. (Requirement 15.)

Requirement 14 is a list of things left out. It has no behaviour to test beyond criterion 2, which would show any stray key.

## Open questions

None.

---
Domain skills applied: dependencies.
