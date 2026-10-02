# Plan: Move the Model 100 to QMK firmware

From `intent.md` (2026-09-29) and `spec.md` (2026-09-29). Status: accepted.

## Context

Kaleidoscope, Chrysalis and Keyboardio's support are abandoned, and the opposite-hands rule only lives in a personal Kaleidoscope fork. This change moves the Model 100 to QMK with the same keys and layers as the current Chrysalis layout, QMK's default dual-use timing plus Permissive Hold, Chordal Hold and Flow Tap, keeps the lights on the port's defaults, and keeps a tested way back to Kaleidoscope. The keymap lives in this repository as a QMK external userspace and is built on Etienne's Mac.

Facts checked while planning (2026-09-30):

- QMK CLI, `dfu-util` and `arduino-cli` are not installed on this Mac. `~/Developer/qmk_firmware` does not exist. Step 0 installs the QMK CLI and clones the source, with Etienne's permission; `arduino-cli` is not needed (Etienne builds the way-back firmware in the Arduino IDE).
- Head of `shieldsd/qmk_firmware@keyboardio-model100-pr` is `2c745388201b633ba04036b17157669632d1740a` (2026-08-15, "[Keyboard] Add Keyboardio Model 100"). That is the commit to pin unless Etienne's clone shows a newer one.
- The port's `matrix.c` (`matrix_init_custom()`) already sets the scanner chips' keyscan interval to 2 on both halves, the same as `setKeyscanInterval(2)` in the sketch. The spec's concern that this has no counterpart rests on a wrong premise; `"debounce": 0` in `keyboard.json` is a separate QMK setting and stays.
- The port's `keyboards/keyboardio/model100/keyboard.json` and its `LAYOUT` lists keys by QMK matrix position. Rows 0–3 of the QMK matrix are the left half, rows 4–7 the right half; Kaleidoscope position is `(row, 7 - col)` for the left and `(row - 4, 15 - col)` for the right.
- `Chrysalis_Keyboardio-Model-100_layout.json` holds `keymaps`: 8 layers × 64 keys in Kaleidoscope order (`r0c0`…`r3c15`). Each key has `code`, and where relevant `baseCode`, `modifier`, `target`, `categories`. The raw `code` is authoritative; the metadata is only cross-checked (Mission Control, code `19106`, has category `platform_apple`, not `consumer`).
- A second-model critique (Codex, 2026-09-30) checked the draft keymap's 256 entries against the raw Chrysalis codes and found no differences beyond the two accepted exceptions, and confirmed the matrix mapping covers all 64 positions exactly once.
- The repository has no test runner, no CI and no lint config apart from `cspell.yml` with `project-dictionary.txt`. `clang-format`, `cspell`, Ruby 4.0.7 (via `rv`) with its bundled Minitest 6.0.6, and RuboCop with Etienne's global `~/.rubocop.yml` are installed.

## Files that change

- `qmk.json` (new) — marks this repository as a QMK userspace. QMK only detects a userspace that already has a valid `qmk.json`, so it is first written by hand with `userspace_version` and empty `build_targets`; `qmk userspace-add` then adds `keyboardio/model100:eirvandelden`.
- `keyboards/keyboardio/model100/keymaps/eirvandelden/keymap.c` (new) — the four layers (`BASE`, `NUMBERS`, `NAVIGATION`, `MEDIA`), starting from the draft in `docs/qmk-migration.md`, with `DV_*` names from `keymap_dvorak.h`. Handedness for Chordal Hold comes from `chordal_hold_handedness(keypos_t key)` returning `'L'` for matrix rows 0–3 and `'R'` for rows 4–7, instead of a hand-typed 64-entry `chordal_hold_layout` table. Same split as Kaleidoscope columns 0–7 versus 8–15, thumbs and palm keys included.
- `keyboards/keyboardio/model100/keymaps/eirvandelden/config.h` (new) — `PERMISSIVE_HOLD`, `CHORDAL_HOLD` and `FLOW_TAP_TERM 150`. Nothing else. On 2026-09-30 Etienne chose QMK's default timing over porting the Qukeys values: this replaces spec requirement 9's `TAPPING_TERM 250` and `QUICK_TAP_TERM 250` and the intent's "dual-use modifier timing behave as they do today". At the pinned commit the defaults are `TAPPING_TERM 200` and `QUICK_TAP_TERM` equal to it (`quantum/action_tapping.h`), and the port's `config.h` changes neither. Chordal Hold (spec requirement 10) stays, with Permissive Hold, because QMK's documentation says Chordal Hold is meant to be used with Permissive Hold or Hold On Other Key Press; without one of them it adds nothing for opposite-hand chords. Flow Tap at 150 ms (the value QMK's documentation suggests) stays as the guard against top-row modifiers firing while typing.
- `keyboards/keyboardio/model100/keymaps/eirvandelden/rules.mk` (new) — enables nothing beyond the port's defaults; in particular no `CAPS_WORD_ENABLE` and no `AUTOCORRECT_ENABLE`. May be empty if the build allows it.
- `bin/keymap-parity` (new, Ruby, standard library only: `json`, `open3`) — the parity check, a thin entry point that wires the objects below together and sets the exit status. The spec says "Python's standard library"; Etienne changed that to Ruby on 2026-09-30, and it still adds no dependency. Behaviour: it reads the Chrysalis JSON, runs `qmk c2json -kb keyboardio/model100 -km eirvandelden --no-cpp <absolute path to keymap.c>` (always `--no-cpp`: the default path runs `cpp` without the firmware's include paths; `--no-cpp` keeps `DV_*`, mod-taps and `MO(MEDIA)` as written, turns `_______`/`XXXXXXX` into `KC_TRNS`/`KC_NO`, and returns layers in textual order without their names) and `qmk info -kb keyboardio/model100 -f json` for the `LAYOUT` matrix positions, turns both sides into the same description per key (plain key with modifiers, dual-use key with tap key and modifier, layer key with target, consumer key with usage code, LED key with action, nothing, transparent), and prints each position whose descriptions differ. Exit status 0 when nothing differs. Known exceptions: the Mission Control position (`0x2A2` against `KC_MCTL`) and base-layer transparent keys against `XXXXXXX`. Chrysalis layer 4 is compared with QMK layer 3; Chrysalis layers 3, 5, 6, 7 must be empty. An unknown QMK name or unknown Chrysalis code stops the script with that name or code, rather than guessing. It also stops when a `qmk` command fails, when there are not exactly four QMK layers of 64 keys, or when the `LAYOUT` positions do not cover all 64 Kaleidoscope positions exactly once. Exceptions are exact pairs, not exempt positions: only base `r1c6` Chrysalis `0x2A2` against `KC_MCTL`, and only base-layer Chrysalis transparent against `KC_NO`.

  Chrysalis decoding contract (from the Kaleidoscope fork; the raw `code` decides, metadata is cross-checked):
  - Plain key: `code < 256` is the HID usage. Keys with modifiers carry Kaleidoscope's modifier flags in bits 8–12 (Control, left Alt, right Alt, Shift, GUI), translated into the same modifier set the QMK side uses; the bit assignments differ from QMK's.
  - Dual-use: `code - 49169`; low byte is the tap usage, high byte is the modifier index 0–7.
  - Consumer: usage is `code & 0x03ff` (Mission Control `19106` gives `0x2A2`).
  - LED: `17152` next, `17153` previous, `17154` toggle.
  - Layer: `17408 + target` locks, `17450 + target` shifts. Target 4 is renumbered to QMK 3, like the layer itself.
  - `65535` transparent, `0` no key.

  QMK side: layer names in `MO()`/`TG()` are resolved from the `enum layers` declaration in `keymap.c`, and the script checks that the layers appear in that declaration order.
- `lib/keymap_parity/chrysalis_layout.rb` (new) — `ChrysalisLayout`: reads the JSON and describes the key at a layer and Kaleidoscope position.
- `lib/keymap_parity/qmk_keymap.rb` (new) — `QmkKeymap`: takes the `qmk c2json` layers and the `LAYOUT` matrix positions, and describes the key at a layer and Kaleidoscope position. Holds the table from QMK names to key codes.
- `lib/keymap_parity/comparison.rb` (new) — `Comparison`: walks every layer and position, applies the two exceptions and the layer renumbering, and reports differences.
- `test/keymap_parity/*_test.rb` (new) — Minitest tests per class, with small hand-written Chrysalis and QMK fragments inline. No real QMK needed to run them.
- `.clang-format` (new) — Google base, `ColumnLimit: 0`, `WhitespaceSensitiveMacros: [LAYOUT]`. `ColumnLimit: 0` alone keeps the line breaks but drops the column padding (Codex checked this with clang-format 23.1.2); `WhitespaceSensitiveMacros` keeps the `LAYOUT(...)` grids as a picture of the keyboard without any disable comments.
- `docs/qmk-migration.md` — change step 3 to clone Etienne's fork `eirvandelden/qmk_firmware` (with `shieldsd` as a second remote) and record the pinned QMK commit; record where the way-back `.bin` is kept and how to go back (flash it from the bootloader with `dfu-util`, then import the Chrysalis layout); correct the `setKeyscanInterval(2)` row of the timing table (the port already sets the interval to 2), replace the Qukeys timing table with what the keymap uses (QMK default timing, Permissive Hold, Chordal Hold, `FLOW_TAP_TERM 150`) and why, keeping the Qukeys values for reference, replace the "Converted keymap (draft, not compiled)" block with a pointer to `keymap.c`, so there is one copy of the keymap; say what has been built and flashed.
- `docs/changes/8-move-the-model-100-to-qmk-firmware/keyboard-checklist.md` (new) — the on-keyboard checks from acceptance criteria 4–12, one tick box each, with one line per key per layer for criterion 4. It adds checks for the numbers and navigation mod-taps and for holding two modifiers together, because Flow Tap's default filter leaves digits, grave and brackets without Flow Tap protection. It says the same-hand `pu` check must be done within 200 ms: after `TAPPING_TERM`, Chordal Hold no longer stops a hold. It has a findings section for regressions seen during the week.
- `project-dictionary.txt` — any new words cspell flags in the files above.

Added while building (2026-10-01):

- `lib/keymap_parity.rb` (new) — the namespace, `KeymapParity::Error` and the shared `MODIFIERS` list; it requires the classes.
- `lib/keymap_parity/qmk_names.rb` (new) — `QmkNames`: the table from QMK names to key codes and the reading of `LCTL(...)`, `LCTL_T(...)`, `MO(...)` and `TG(...)`. Split out of `QmkKeymap` to keep both classes small. `QmkKeymap` keeps the matrix mapping, the shape checks, the enum check and the `qmk` calls (`QmkKeymap::Command`).
- `test/test_helper.rb` (new) — builds Chrysalis and QMK fragments for the tests.
- `test/keymap_parity/fixtures/c2json.json` and `qmk_info.json` (new) — the real tool output from steps 3 and 6.
- `.gitignore` (new) — `*.bin`, `*.hex`, `.build/`, because `qmk compile` copies the firmware into the repository root.
- Extra tests beyond the list below: Chrysalis plain, no-key, transparent, consumer, LED and layer decoding; inner-column position; names decoded as Chrysalis does; layer designators after a closing parenthesis; no difference on untouched keymaps; Mission Control against `KC_MCTL` elsewhere.
- The layer designator check looks for `[NAME] = LAYOUT` anywhere in the line, because `clang-format` joins `), [NUMBERS] = LAYOUT(` onto one line.
- `qmk compile` needs the keg-only Homebrew compilers on `PATH` (`/opt/homebrew/opt/arm-none-eabi-gcc@8/bin` and `/opt/homebrew/opt/arm-none-eabi-binutils/bin`); `brew link` was not run. `user.overlay_dir` points at this worktree.

Not changed: `Model01/`, `Model100/`, `Chrysalis_Keyboardio-Model-100_layout.json`, `Chrysalis_Keyboardio-Model-01_layout.json`, `Chrysalis.pdf`, `README.md`.

Added after the first flash (2026-10-02), at Etienne's request — the port's 29 light effects are too many:

- `keyboards/keyboardio/model100/keymaps/eirvandelden/config.h` — `#undef` the port's effects except `ENABLE_RGB_MATRIX_BREATHING` and `ENABLE_RGB_MATRIX_CYCLE_LEFT_RIGHT` (rainbow wave). Add `ENABLE_RGB_MATRIX_SOLID_REACTIVE_SIMPLE` (key-press fade) with `RGB_MATRIX_KEYPRESSES`, which that effect needs. QMK reads the keymap's `config.h` after the keyboard's generated `info_config.h`, so the `#undef`s take effect. QMK's solid colour effect is always compiled in and cannot be removed, so it stays in the cycle.
- `keyboards/keyboardio/model100/keymaps/eirvandelden/rgb_matrix_user.inc` (new) and `rules.mk` (`RGB_MATRIX_CUSTOM_USER = yes`) — a custom `lights_off` effect that sets every LED to black, so "off" is a step of the LED key's cycle, as on Kaleidoscope.
- `keymap.c` — `keyboard_post_init_user()` switches to `lights_off` without saving it (`rgb_matrix_mode_noeeprom`), so the keyboard starts with the lights off on every power-up, as Kaleidoscope returned to its default mode. This also avoids a saved mode number from the 29-effect list pointing at a different effect.
- The LED key then cycles: solid colour, breathing, rainbow wave, key-press fade, off.
- Proof: `qmk compile` succeeds; on the keyboard, the checklist's "Light keys" checks. The `## Out of scope` LED line still holds for #11's rainbow trail, per-layer colours, idle and sleep.

Found on the keyboard (2026-10-02): the left inner middle key opened Spotlight on Kaleidoscope, not Mission Control. Chrysalis labels its code (consumer usage `0x2A2`) "Mission Control", and the spec followed that label with `KC_MCTL`, which opens Mission Control. Etienne needs Spotlight:

- `keymap.c` — that key becomes `LGUI(KC_SPC)` (Cmd+Space). Cmd+Space is the Spotlight shortcut itself, so it does not depend on how macOS reads consumer usages.
- `lib/keymap_parity/comparison.rb` — the accepted exception at base layer `r1c6` becomes Chrysalis `0x2A2` against QMK Cmd+Space, named for Spotlight. `KC_MCTL` at that position is now a difference.
- `docs/qmk-migration.md` and `keyboard-checklist.md` — name the key Spotlight and drop the `KC_MCTL` advice.
- Tests first in `test/keymap_parity/comparison_test.rb`: Cmd+Space at the Spotlight position is allowed, `KC_MCTL` there is reported, and Cmd+Space elsewhere against `0x2A2` is reported.
- This replaces the intent's and spec's `KC_MCTL` constraint, which rested on the Chrysalis label rather than on what the key did, and every `KC_MCTL` exception in this plan's file list and Proof.

Found on the keyboard (2026-10-02): typing `word?` at speed gave `ppp/`. Flow Tap settled the left Shift key (`p`) as a tap because it came within 150 ms of a letter, and macOS key repeat then typed `p` while the key was held. With a pause first, `word?` types correctly. Etienne chose to take the Shift keys out of Flow Tap:

- `keymap.c` — `get_flow_tap_term()` returns 0 for mod-taps whose modifier is Shift (`LSFT_T(DV_P)`, `RSFT_T(DV_G)`, `LSFT_T(DV_4)`, `RSFT_T(DV_7)`), and QMK's default rule (`FLOW_TAP_TERM` when both keys are flow-tap keys) for every other key. Ctrl, Alt and Cmd keep Flow Tap.
- Proof: `qmk compile` succeeds; on the keyboard, `word?` typed at speed gives `word?`, and typing `people` still fires no modifier.

## Order of work

0. Set up the QMK tools. On 2026-09-30 Etienne gave the implementing agent explicit permission to install the QMK tools and clone the QMK source. This overrides the intent's "I install the QMK tools on my machine myself" and playbook rule 8 for these commands only:
   - First, the agent creates the fork. On 2026-10-01 Etienne asked for this to be the first step. Run `gh repo fork shieldsd/qmk_firmware --clone=false`. Do not pass `--default-branch-only`, so every branch is copied, `keyboardio-model100-pr` included. This creates the public repository `eirvandelden/qmk_firmware`. GitHub creates forks in the background, so wait until `gh api repos/eirvandelden/qmk_firmware --jq .parent.full_name` prints `shieldsd/qmk_firmware` and `gh api repos/eirvandelden/qmk_firmware/branches/keyboardio-model100-pr --jq .commit.sha` prints a commit. Try at most twelve times, a few seconds apart. If the fork is still missing, or the branch is not there, stop and report.
   - `brew install qmk/qmk/qmk` (brings the ARM compiler and `dfu-util`). Then `qmk doctor`, answering no to anything it offers to install or change (check `qmk doctor --help` for the non-interactive flag first). Report anything it flags; do not fix it.
   - `git clone --recurse-submodules -b keyboardio-model100-pr https://github.com/eirvandelden/qmk_firmware.git ~/Developer/qmk_firmware`, then `git -C ~/Developer/qmk_firmware remote add shieldsd https://github.com/shieldsd/qmk_firmware.git` for later updates. Record the checked-out commit (`git -C ~/Developer/qmk_firmware rev-parse HEAD`); it should be `2c745388201b633ba04036b17157669632d1740a`. If it is not, stop and ask Etienne which one to pin. Nothing is pushed to the fork on this branch.
   - `qmk config user.qmk_home="$HOME/Developer/qmk_firmware"`.
   - `qmk compile -kb keyboardio/model100 -km default` builds. If it does not, stop and report.
   - `qmk config user.overlay_dir="<path to this worktree>"`, so the build reads this repository.
   - Nothing else gets installed. If a tool is missing beyond these, stop and ask.

   Etienne does by hand, before any QMK flash: build the way-back firmware from commit `1ee038c` of this repository against `~/Developer/Kaleidoscope` in the Arduino IDE, and keep the `.bin` outside the repository (for example `~/Documents/keyboardio/model100-kaleidoscope-1ee038c.bin`). All flashing is Etienne's.
1. Write the acceptance test for criterion 1: run `qmk compile -kb keyboardio/model100 -km eirvandelden`. Watch it fail because keymap `eirvandelden` does not exist.
2. Walking skeleton: write the minimal `qmk.json` by hand (`userspace_version`, empty `build_targets`), add `.clang-format`, `keymap.c` with the base layer only, and empty `config.h` and `rules.mk`, then run `qmk userspace-add -kb keyboardio/model100 -km eirvandelden`. Compile. Green. Commit.
3. Try the tool boundary before writing the decoder: run the exact `qmk c2json ... --no-cpp` command on the skeleton and `qmk info -kb keyboardio/model100 -f json`, and keep their real output as test data under `test/keymap_parity/fixtures/`. Adjust the plan's description of that output if it differs.
4. Unit tests for the parity check, red then green, one behaviour at a time (list under Proof). Commit on green.
5. Run `bin/keymap-parity` against the base-only keymap. Watch it fail because there is one QMK layer instead of four. That is the acceptance test for criterion 2 failing for the right reason.
6. Add `NUMBERS`, `NAVIGATION`, `MEDIA` from the draft. Compile. Run `bin/keymap-parity`. Fix each listed difference in `keymap.c` until it reports none. Save the real `c2json` output of the full keymap over the step 3 fixture, so the integration test covers all four layers. Commit.
7. `config.h` with `PERMISSIVE_HOLD`, `CHORDAL_HOLD` and `FLOW_TAP_TERM 150`, `chordal_hold_handedness()` in `keymap.c`. Compile. Parity still clean. Commit.
8. Criterion 3: `git diff --exit-code main -- Model01 Model100 Chrysalis_Keyboardio-Model-100_layout.json` shows nothing.
9. Criterion 12: `grep -rnE 'CAPS_WORD|AUTOCORRECT|CW_TOGG|QK_CAPS_WORD|AC_TOGG|AC_ON|QK_AUTOCORRECT' keyboards/ qmk.json` exits 1 (no match; exit 2 is an error, not a pass), and the effective build settings (`qmk info -kb keyboardio/model100 -km eirvandelden -f json`, flag checked with `--help` first) show neither `caps_word` nor `autocorrect` enabled.
10. Update `docs/qmk-migration.md` and write `keyboard-checklist.md`. Run `cspell` on every changed file, `clang-format --dry-run --Werror` on `keymap.c` and `config.h`, using the new `.clang-format`, and `rubocop bin lib test` (global config, no project `.rubocop.yml`) plus the Minitest tests. Add dictionary words. Commit, push, open the pull request against `origin` using the repository's template if one exists.

Etienne, on the keyboard, in parallel with the agent's steps; the agent does not wait for these:

- Once the way-back `.bin` is kept, flash the port's `default` keymap (doc step 4) and type on it. That shows whether the port works on this keyboard before the own keymap matters.
- After step 7, flash `eirvandelden` with `qmk flash -kb keyboardio/model100 -km eirvandelden` and work through `keyboard-checklist.md` (criteria 4–9 and 12).
- Try the way back once (criterion 10) and flash QMK again.
- A week of normal work (criterion 11). Doubled letters, accidental modifiers or any other regression go into the checklist's findings section. For each, Etienne decides whether it blocks the change. A fix that needs new work gets a new plan step first; it is not improvised on this branch.

## Risks

- **The port's branch moves or is rebased.** The build uses Etienne's fork `eirvandelden/qmk_firmware`, so a force-push to `shieldsd` does not change it. The commit is also pinned in `docs/qmk-migration.md`.
- **`qmk c2json` misreads the keymap.** It parses C with a limited parser. Step 3 runs it on the real skeleton before any decoder exists, and the script always uses `--no-cpp`. If it still fails, stop and ask; do not rewrite the keymap into `keymap.json`.
- **The parity script's QMK name table is wrong or incomplete.** The script holds its own table from QMK names to key codes for the names this keymap uses. A wrong entry would hide a real difference. Mitigated by unit tests per name group, by stopping on unknown names, and by criterion 4 (every key checked on the keyboard once). Rejected: reading QMK's own `data/constants/keycodes/*.hjson`, because Ruby's standard library cannot parse hjson.
- **Timing feels different.** The keyboard decides tap or hold after 200 ms instead of 250 ms, and a tap then hold repeats the tap only within 200 ms instead of 300 ms. Permissive Hold still makes a quick opposite-hand chord (hold `p`, tap `h`, release `p`) type `H`. Flow Tap is not a copy of Kaleidoscope's minimum prior interval: QMK's default filter skips digits, grave and brackets, and Flow Tap is off during some modifier chords and while a tap-hold is undecided. The week of daily use is the test; tuning goes to a later change.
- **This branch stays open for the week of typing** (criterion 11). The pull request is opened at step 10 and merges only after the week passes without a reason to go back.
- **Doubled letters.** The port already sets the scanner interval to 2, like the sketch. No debounce algorithm is added; doubled letters seen on the keyboard are recorded as a finding.
- **Mission Control does something different on the Mac.** Accepted by the spec (`KC_MCTL`). It did: the key opened Spotlight on Kaleidoscope. Replaced on 2026-10-02 by Cmd+Space; see the Spotlight addition above.
- **Lights stay on while the Mac sleeps.** Accepted until #11.
- **Settings area overwritten.** QMK and Kaleidoscope share the flash area for settings. After going back, the Chrysalis layout import restores it; that is part of criterion 10.
- Rejected: a hand-typed `chordal_hold_layout` table (64 entries to get wrong, and it must follow `LAYOUT` order); the handedness callback derives it from the matrix row. Rejected: Tri Layer for the media layer (spec keeps the palm-key `MO(MEDIA)`). Rejected: generating `keymap.c` from the Chrysalis JSON (spec: written by hand, JSON is being retired).

## Out of scope

- LED behaviour beyond port defaults: rainbow trail on key press, per-layer colours, idle and sleep timeouts (#11).
- Building in GitHub Actions (#10).
- Removing `Model01/`, `Model100/`, the Chrysalis files or the Kaleidoscope fork (follow-up branch).
- Miryoku research (#9).
- Caps Word, Autocorrect, Flow Tap value tuning, per-key tapping term, Speculative Hold, combos, Tap Dance, Key Overrides, Leader, Layer Lock, Repeat Key, Raw HID.
- Mouse keys, macros, dynamic macros, one-shot keys, SpaceCadet, magic combos, steno, the boot greeting.
- Moving `user.qmk_home` to upstream QMK after qmk/qmk_firmware#26397 merges.

## Proof

- 1. Firmware compiles against the recorded commit → `qmk compile -kb keyboardio/model100 -km eirvandelden` exits 0.
- 2. Every key on base, numbers, navigation and media matches Chrysalis apart from the two exceptions → `bin/keymap-parity` exits 0 and prints no differences. Etienne accepted on 2026-09-30 that a wrong entry in the script's own name table is caught by criterion 4, the one pass over every key on the keyboard.
- 3. Kaleidoscope sketches and Chrysalis layout unchanged → `git diff --exit-code main -- Model01 Model100 Chrysalis_Keyboardio-Model-100_layout.json`.
- 4. Each key on each layer types what Chrysalis says → `keyboard-checklist.md` "Every key, every layer".
- 5. Right palm + right arrow; both palms + volume up → `keyboard-checklist.md` "Palm keys reach the layers".
- 6. Top-row `p` taps `p`; held with `h` on the other hand types `H` → `keyboard-checklist.md` "Dual-use key taps and holds".
- 7. `p`/Shift then `u` on the same hand types `pu` → `keyboard-checklist.md` "Same hand types letters".
- 8. `people` at normal speed triggers no modifier → `keyboard-checklist.md` "Typing people".
- 9. LED next changes the effect, LED toggle turns the lights off and on → `keyboard-checklist.md` "Light keys".
- 10. Way back to Kaleidoscope tried once, then QMK again → `keyboard-checklist.md` "Way back tried".
- 11. A week of normal work on QMK → `keyboard-checklist.md` "A week of work".
- 12. No Caps Word or Autocorrect key or feature → the recursive `grep` in step 9 exits 1 and the effective build settings show neither feature; `keyboard-checklist.md` records it.

Per changed file, the unit tests expected, named as behaviour:

- `lib/keymap_parity/*` (Minitest `test_*` methods; the matrix-position, layer-count, key-count, layout-coverage, enum-order, failing-command and unknown-name tests live in `test/keymap_parity/qmk_keymap_test.rb`; the Chrysalis decoding and unknown-code tests in `test/keymap_parity/chrysalis_layout_test.rb`; the rest, which compare a Chrysalis key with a QMK key, in `test/keymap_parity/comparison_test.rb`):
  - `test_left_half_matrix_position_maps_to_kaleidoscope_column_seven_minus_column`
  - `test_right_half_matrix_position_maps_to_kaleidoscope_column_fifteen_minus_column`
  - `test_plain_chrysalis_key_matches_its_dvorak_name` (code 51 against `DV_S`)
  - `test_chrysalis_key_with_shift_matches_shifted_dvorak_name` (code 2093 against `DV_LCBR`)
  - `test_chrysalis_key_with_control_matches_lctl_wrapper` (`LCTL(DV_S)`)
  - `test_dual_use_key_matches_mod_tap_with_same_tap_key_and_modifier` (`LCTL_T(DV_QUOT)`)
  - `test_dual_use_key_with_wrong_modifier_is_reported`
  - `test_shift_to_layer_matches_mo_and_lock_to_layer_matches_tg`
  - `test_chrysalis_layer_four_is_compared_with_qmk_media_layer`
  - `test_consumer_keys_match_media_and_brightness_names`
  - `test_led_keys_match_rm_next_rm_prev_rm_togg`
  - `test_transparent_on_upper_layer_matches_transparent`
  - `test_transparent_on_base_layer_matches_no_key`
  - `test_spotlight_position_may_send_cmd_space_for_the_chrysalis_consumer_code` (was `test_mission_control_position_is_allowed_to_differ`, renamed on 2026-10-02)
  - `test_unused_chrysalis_layer_that_is_not_empty_is_reported`
  - `test_unknown_qmk_name_stops_with_that_name`
  - `test_report_lists_layer_and_kaleidoscope_position_for_each_difference`
  - `test_modifier_flags_on_a_chrysalis_key_are_translated_to_the_same_modifiers_as_qmk`
  - `test_dual_use_code_gives_tap_key_from_low_byte_and_modifier_from_high_byte`
  - `test_mission_control_is_decoded_from_its_code_not_its_category`
  - `test_layer_key_target_four_is_renumbered_to_three`
  - `test_unknown_chrysalis_code_stops_with_that_code`
  - `test_a_different_key_at_the_spotlight_position_is_reported` (was `test_a_different_key_at_the_mission_control_position_is_reported`, renamed on 2026-10-02)
  - `test_a_base_layer_key_that_is_not_transparent_against_no_key_is_reported`
  - `test_qmk_keymap_without_exactly_four_layers_is_refused`
  - `test_qmk_layer_without_sixty_four_keys_is_refused`
  - `test_layout_positions_that_miss_or_repeat_a_kaleidoscope_position_are_refused`
  - `test_layer_names_are_resolved_from_the_enum_and_must_follow_its_order`
  - `test_failing_qmk_command_stops_with_its_output`
  - `test_real_chrysalis_export_against_real_c2json_output_reports_no_differences` (written in step 6, once the full keymap exists; uses the fixture saved there and the committed Chrysalis JSON)
- `keymap.c`, `config.h`, `rules.mk`, `.clang-format`: no unit tests; proven by compile (criterion 1), `bin/keymap-parity` (criterion 2) and the checklist.

Test setup: `ruby -Ilib -Itest -e 'Dir["test/**/*_test.rb"].each { require File.expand_path(it) }'` (or one file: `ruby -Ilib -Itest test/keymap_parity/comparison_test.rb`). Tests build tiny Chrysalis and QMK layer fragments inline and inject the `qmk` command runner, so they run without QMK installed. One integration test reads the real `c2json` and `qmk info` output saved in step 3. The acceptance runs (`qmk compile`, `bin/keymap-parity`) need step 0 done first.

<!-- cspell:words rubocop RuboCop keypos TRNS worktree Werror hjson Ilib Itest noeeprom -->
