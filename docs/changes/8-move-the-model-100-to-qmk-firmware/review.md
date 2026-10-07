# Review: 8-move-the-model-100-to-qmk-firmware

## Round 1 — 2026-10-01T09:17Z — c447710

Scope: `origin/main...HEAD` (documentation only: `docs/qmk-migration.md`, `cspell.yml`, `project-dictionary.txt`, `intent.md`, `spec.md`, `plan.md`). Working tree clean. No `REVIEW.md` in the repository; default passes used (Bugs, Security, Compliance). The repository has no test suite; `cspell` on all six changed files reports 0 issues. The draft keymap's thumb, palm, inner-column, layer-target and media positions were spot-checked against the raw codes in `Chrysalis_Keyboardio-Model-100_layout.json` and match. The Dvorak tables for Caps Word, Autocorrect and `SEND_STRING` are correct.

Compliance, spec acceptance criteria against proof in the diff (implementation has not started, so nothing is proven yet):

| Criterion | Proof in diff |
|---|---|
| 1. `eirvandelden` compiles against the recorded commit | missing |
| 2. Parity script reports no differences | missing (`bin/keymap-parity` absent) |
| 3. Sketches and Chrysalis layout unchanged | holds today (`git diff origin/main...HEAD -- Model01 Model100 Chrysalis_Keyboardio-Model-100_layout.json` is empty); no recorded check yet |
| 4–11. On-keyboard checks | missing (`keyboard-checklist.md` absent) |
| 12. No Caps Word or Autocorrect | missing |

None of the 30 unit tests named in `plan.md` `## Proof` exist yet (`test/keymap_parity/` absent). No existing test was weakened, skipped or deleted.

- [x] Important: Step 1 says to build the way-back firmware from `Model100/Model100.ino` "on `main`". `main` now contains the availability-light merge (#7, `1c57d46`), so following this builds the firmware that was never flashed. Spec requirement 12 says commit `1ee038c`. The plan's doc-update list only says "record where the way-back `.bin` is kept", so this line may survive step 10 — `docs/qmk-migration.md:38` → fixed (Document the QMK migration as built and add the keyboard checklist)
- [x] Important: The userspace setup runs `qmk userspace-add` without first creating `qmk.json`. The plan's own finding says QMK only detects a userspace that already has a valid `qmk.json`, so these instructions fail as written. The plan's doc-update list for step 10 does not include this fix — `docs/qmk-migration.md:88` → fixed (Document the QMK migration as built and add the keyboard checklist)
- [x] Important: Compliance: no spec acceptance criterion has proof yet, and none of the tests named in `plan.md` `## Proof` exist. Expected before implementation, but the branch cannot be pushed for review or merged in this state — `docs/changes/8-move-the-model-100-to-qmk-firmware/plan.md:100` → fixed (Document the QMK migration as built and add the keyboard checklist)
- [x] Nit: Space is on the right thumb (Chrysalis `r1c8` = 44; the draft's last `LAYOUT` row alternates L/R, which puts `KC_SPC` on the right). "left mod plus left-thumb `Enter` or `Space`" should name only `Enter` (or `Tab`/`Esc`) — `docs/qmk-migration.md:212` → fixed (Put the inner-column keys and the left thumb right in the guide)
- [x] Nit: "The inner-column keys ... sit at the end of rows 1–3" disagrees with the draft below it, where they sit in positions 6–7 of each 14-key row, between the halves. Say "at the end of each half's row" or "in the middle of rows 1–3" — `docs/qmk-migration.md:130` → fixed (Put the inner-column keys and the left thumb right in the guide)
- [x] Nit: "They are system tools, and an agent should not install them" contradicts plan step 0, where Etienne gave the implementing agent permission to install the QMK CLI and clone the source. Not in the plan's doc-update list — `docs/qmk-migration.md:46` → fixed (Document the QMK migration as built and add the keyboard checklist)
- [x] Nit: "flash the kept Kaleidoscope `.bin` with the same `dfu-util` command as in step 4". Step 4 runs `qmk flash` and only paraphrases the `dfu-util` call with a `<firmware>.bin` placeholder. Spec requirement 13 asks the doc to describe the way back, so give the literal command with the kept file's path — `docs/qmk-migration.md:42` → fixed (Give the way-back flash command the kept file's path)
- [x] Nit: `cspell.yml` points to the machine-local `~/.config/cspell/user-dictionary.txt` with `addWords: true`. Words added from this repository can go to the personal dictionary instead of `project-dictionary.txt`, and a fresh clone without that file gets a missing-dictionary warning — `cspell.yml:7` → fixed (Keep the spell check inside the repository)

## Round 2 — 2026-10-01T15:56Z — 6ca0c60

Scope: `origin/main...HEAD` (16 commits, 26 files). The working tree is clean, and the branch is 8 commits ahead of `origin`. There is no `REVIEW.md`, so the default passes ran: Bugs, Security, Compliance.

Run on this machine:

- `ruby -Ilib -Itest -e 'Dir["test/**/*_test.rb"].each { require File.expand_path(it) }'`: 42 runs, 109 assertions, 0 failures.
- `rubocop bin lib test`: 9 files, no offenses.
- `clang-format --dry-run --Werror` on `keymap.c` and `config.h`: clean.
- `cspell` on every changed file: 0 issues.
- `qmk compile -kb keyboardio/model100 -km eirvandelden` (QMK at `2c745388201b633ba04036b17157669632d1740a`, the keg-only compilers on `PATH`): exits 0, and the build artefacts are ignored by `.gitignore`.
- `bin/keymap-parity`: exits 0 and prints nothing.
- The current `qmk c2json --no-cpp` output equals `test/keymap_parity/fixtures/c2json.json`, so the fixture is current.

Bugs pass: the Kaleidoscope decoding was checked against the fork's constants: modifier flags in bits 8–12, dual-use at 49169, consumer at `0x48xx`, LED at 17152–17154, lock at 17408 and shift at 17450. The matrix mapping was checked against the `qmk info` fixture: the thumb row alternates left and right, and the inner columns sit at positions 6–7 of each row. The Chrysalis layer keys target only layers 1, 2 and 4. The Chordal Hold callback splits the matrix at `MATRIX_ROWS / 2`, which gives the documented rows 0–3 and 4–7.

Security pass: nothing found. `QmkKeymap::Command` passes an argument array to `Open3.capture3`, without a shell. The repository has no secrets, no CI and no deploy configuration.

Round 1: its three Important findings are resolved in the current files (`1ee038c` in step 1, `qmk.json` written by hand before `userspace-add`, proofs now present), and so are its `dfu-util` and "agent should not install" nits. Their `→` slots are still empty. Two round 1 nits are still open and appear again below.

Compliance, spec acceptance criteria against proof in the diff:

| Criterion | Proof |
|---|---|
| 1. `eirvandelden` compiles against the recorded commit | `qmk compile` exits 0 (run above); commit pinned in `docs/qmk-migration.md` |
| 2. Parity on base, numbers, navigation and media | `bin/keymap-parity` exits 0; `test_real_chrysalis_export_against_real_c2json_output_reports_no_differences` |
| 3. Sketches and Chrysalis layout unchanged | `git diff --exit-code origin/main -- Model01 Model100 Chrysalis_Keyboardio-Model-100_layout.json` exits 0 |
| 4–11. On-keyboard checks | `keyboard-checklist.md` sections exist, nothing ticked yet (nothing has been flashed; expected, the branch stays open for the week) |
| 12. No Caps Word or Autocorrect | the plan's `grep` exits 1; `rules.mk` is empty; checklist entry exists |

All 30 tests named in `plan.md` `## Proof` exist. No existing test was weakened, skipped or deleted (the branch adds the repository's first tests). Requirement 9 in `spec.md` still says `TAPPING_TERM 250` and `QUICK_TAP_TERM 250`. `plan.md` records Etienne's 2026-09-30 choice of QMK's default timing instead, and `config.h` follows the plan.

- [x] Nit: The plan's test command fails with `cannot load such file -- test_helper (LoadError)`, because the tests `require "test_helper"` and `test/` is not on the load path. Add `-Itest` to both commands. The repository documents no other way to run the tests — `docs/changes/8-move-the-model-100-to-qmk-firmware/plan.md:161` → fixed (Give the plan's test command the test directory on the load path)
- [x] Nit: `MEDIA_TARGET` renumbers only target 4. A Chrysalis layer key that targets empty layer 3 also decodes to target 3, so it would match `MO(MEDIA)` or `TG(MEDIA)`, and the parity check would pass. Today's export targets only 1, 2 and 4, so no difference is hidden now. Raising on a target in `Comparison::UNUSED_LAYERS` would close the gap — `lib/keymap_parity/chrysalis_layout.rb:12` → fixed (Refuse layer keys that point at a layer the QMK keymap drops)
- [x] Nit: `bin/keymap-parity` rescues only `KeymapParity::Error`. A `qmk` command that exits 0 but prints non-JSON, or an invalid Chrysalis file, ends in a raw `JSON::ParserError` backtrace instead of a `keymap-parity:` message — `bin/keymap-parity:9` → fixed (Stop the parity check with a readable message on output that is not JSON)
- [x] Nit: Still open from round 1. "The inner-column keys ... sit at the end of rows 1–3" disagrees with `keymap.c` and the `qmk info` layout, where they are positions 6–7 of each 14-key row, between the halves — `docs/qmk-migration.md:134` → fixed (Put the inner-column keys and the left thumb right in the guide)
- [x] Nit: Still open from round 1. Space is on the right thumb (layout matrix `[5, 7]`; the checklist also lists it under "Right thumb keys"). "a left mod plus left-thumb `Enter` or `Space`" should name only left-thumb keys, for example `Enter` or `Tab` — `docs/qmk-migration.md:188` → fixed (Put the inner-column keys and the left thumb right in the guide)

1 more nit not listed (`qmk.json` has no trailing newline). → fixed (End qmk.json with a newline)

## Round 3 — 2026-10-02T07:58Z — 3bb6910

Scope: `origin/main...HEAD` (26 commits, 26 files), with focus on the 9 commits since round 2 (`d9dfc69..3bb6910`). The working tree is clean. There is no `REVIEW.md`, so the default passes ran: Bugs, Security, Compliance.

Run on this machine:

- Minitest (the plan's command, now with `-Itest`): 45 runs, 118 assertions, 0 failures.
- `rubocop bin lib test`: 9 files, no offenses.
- `clang-format --dry-run --Werror` on `keymap.c` and `config.h`: clean.
- `cspell` on every changed file: 0 issues.
- `qmk compile -kb keyboardio/model100 -km eirvandelden` (QMK at `2c745388201b633ba04036b17157669632d1740a`, the keg-only compilers on `PATH`): exits 0.
- `bin/keymap-parity`: exits 0 and prints nothing.
- `git diff --exit-code origin/main -- Model01 Model100 Chrysalis_Keyboardio-Model-100_layout.json`: exits 0.
- The plan's Caps Word and Autocorrect `grep`: exits 1.

Bugs pass: the round 2 fixes hold. `LAYER_PAIRS` moved to the namespace and now drives both the layer pairing in `Comparison` and the target renumbering in `ChrysalisLayout`, so a layer key that targets dropped layer 3 stops the script. `KeymapParity.parse_json` turns non-JSON from both `qmk` commands and the Chrysalis file into `KeymapParity::Error`. `qmk.json` ends with a newline. `cspell.yml` reads only the project dictionary. The doc corrections for the inner-column keys and the left thumb match `keymap.c`. `brew trust` exists in this Homebrew (`brew help trust`); the trust commands in the guide were not run in this review.

Security pass: nothing found. No new external input beyond the JSON handling above.

Compliance: unchanged from round 2. Criteria 1–3 and 12 are proven by the runs above. Criteria 4–11 wait on the keyboard, and `keyboard-checklist.md` has nothing ticked. The way-back `.bin` (spec requirement 12) does not exist yet at `~/Documents/keyboardio/`; the guide says so, and it is required only before the first QMK flash. All 30 tests named in `plan.md` `## Proof` still exist, and the 3 new tests only add. No test was weakened, skipped or deleted.

- [x] Nit: The round 2 fix covers only invalid JSON. Valid JSON of the wrong shape still ends in a raw backtrace instead of a `keymap-parity:` message: `info.dig(...)` returns `nil` and `.map` raises `NoMethodError`, `fetch("layers")` and `fetch("keymaps")` raise `KeyError`, and a missing Chrysalis file raises `Errno::ENOENT` — `lib/keymap_parity/qmk_keymap.rb:25` → fixed (Stop the parity check with a readable message on input of the wrong shape)
- [x] Nit: The new refusal for a layer key that targets a dropped layer names the target but not where the key is. On the unused layers 3, 5, 6 and 7 it also stops the script before `Comparison#unused` can list the key as "expected an empty layer" with its position. Adding the layer and `r<row>c<col>` to the message would make it actionable — `lib/keymap_parity/chrysalis_layout.rb:60` → fixed (Name the layer and position of a Chrysalis key the check cannot decode)

## Round 4 — 2026-10-02T08:02Z — 2122c03

Scope: `origin/main...HEAD` (30 commits, 26 files), with focus on the 3 commits since round 3 (`3bb6910..2122c03`). The working tree is clean. There is no `REVIEW.md`, so the default passes ran: Bugs, Security, Compliance.

Run on this machine:

- Minitest (the plan's command): 49 runs, 130 assertions, 0 failures.
- `rubocop bin lib test`: 9 files, no offenses.
- `clang-format --dry-run --Werror` on `keymap.c` and `config.h`: clean.
- `cspell` on every changed file: 26 files, 0 issues.
- `qmk compile -kb keyboardio/model100 -km eirvandelden` (QMK at `2c745388201b633ba04036b17157669632d1740a`, the keg-only compilers on `PATH`): exits 0.
- `bin/keymap-parity`: exits 0 and prints nothing.
- `git diff --exit-code origin/main -- Model01 Model100 Chrysalis_Keyboardio-Model-100_layout.json`: exits 0.
- The plan's Caps Word and Autocorrect `grep`: exits 1.

Bugs pass: the round 3 fixes hold. A missing Chrysalis file, a Chrysalis export without `keymaps`, `qmk info` without a `LAYOUT` layout and `qmk c2json` without `layers` now stop with a `keymap-parity:` message. A key the check cannot decode now names its Chrysalis layer and `r<row>c<col>`. A layer key on an unused layer still stops the script instead of being listed by `Comparison#unused`; with the position in the message, that is actionable, as round 3 asked.

Security pass: nothing found. No new external input.

Compliance: unchanged from round 3. Criteria 1–3 and 12 are proven by the runs above. Criteria 4–11 wait on the keyboard, and `keyboard-checklist.md` has nothing ticked. All 30 tests named in `plan.md` `## Proof` still exist, and the 4 new tests only add. No test was weakened, skipped or deleted.

- [x] Nit: `test_qmk_output_of_the_wrong_shape_stops_with_a_readable_message` returns `{}` for both `qmk` commands, so the `qmk info` check fires first and the new `"qmk c2json printed no layers"` branch never runs in a test. The assertion (`"qmk"`) is also loose enough to pass on either message. Give `qmk info` the fixture output and assert on `"layers"` — `test/keymap_parity/qmk_keymap_test.rb:96` → fixed (Test each wrong-shaped qmk output on its own)
- [x] Nit: Two wrong shapes in the Chrysalis export still end in a raw backtrace: a key without `"code"` raises `KeyError`, and a layer with fewer than 64 keys raises `IndexError` (both checked in this review). `ChrysalisLayout#key` rescues only `KeymapParity::Error`. A real Chrysalis export does not have these shapes, so this is low value — `lib/keymap_parity/chrysalis_layout.rb:28` → fixed (Name the position of a Chrysalis key that has no code or is missing)

## Round 5 — 2026-10-02T08:05Z — 40acf01

Scope: `origin/main...HEAD` (34 commits, 26 files), with focus on the 3 commits since round 4 (`5a589ee..40acf01`). The working tree is clean. There is no `REVIEW.md`, so the default passes ran: Bugs, Security, Compliance.

Run on this machine:

- Minitest (the plan's command): 52 runs, 139 assertions, 0 failures.
- `rubocop bin lib test`: 9 files, no offenses.
- `clang-format --dry-run --Werror` on `keymap.c` and `config.h`: clean.
- `cspell` on every changed file: 26 files, 0 issues.
- `qmk compile -kb keyboardio/model100 -km eirvandelden` (QMK at `2c745388201b633ba04036b17157669632d1740a`, the keg-only compilers on `PATH`): exits 0.
- `bin/keymap-parity`: exits 0 and prints nothing.
- `git diff --exit-code origin/main -- Model01 Model100 Chrysalis_Keyboardio-Model-100_layout.json`: exits 0.
- The plan's Caps Word and Autocorrect `grep`: exits 1.

Bugs pass: the round 4 fixes hold. The `qmk c2json` and `qmk info` wrong-shape tests now each feed one bad output, and each asserts on its own message, so both branches run. A Chrysalis key without `"code"` and a layer with fewer than 64 keys now stop with the layer and `r<row>c<col>`. The new `KeyError` rescue in `ChrysalisLayout#key` does not hide a real decoding error: `MODIFIERS.fetch(value >> 8)` gets 0–7 only, and the other `fetch` calls guard with `key?` or a block. A `null` key or a string `"code"` still raises `NoMethodError` (checked in this review). A real Chrysalis export does not have these shapes. The parity script has now been hardened over three rounds against input it does not get, so no finding is raised for this; it is not worth another round.

Security pass: nothing found. No new external input.

Compliance: unchanged from round 4. Criteria 1–3 and 12 are proven by the runs above. Criteria 4–11 wait on the keyboard; in `keyboard-checklist.md` only the two criterion 12 lines are ticked. The way-back `.bin` (spec requirement 12) is not yet at `~/Documents/keyboardio/`; it is required before the first QMK flash. All 30 tests named in `plan.md` `## Proof` still exist. Round 4 replaced one test with two narrower ones and added two; none was weakened, skipped or deleted. The branch is 26 commits ahead of its `origin` branch, so this round and rounds 3–4 are not pushed yet.

No findings.

## Round 6 — 2026-10-02T09:28Z — c45700f

Scope: `origin/main...HEAD` (44 commits, 27 files), with focus on the 9 commits since round 5 (`89263c7..c45700f`): the Spotlight key, the cut to four light effects plus off, the lights starting off, and the Shift keys taken out of Flow Tap. The working tree is clean. There is no `REVIEW.md`, so the default passes ran: Bugs, Security, Compliance.

Run on this machine:

- Minitest (the plan's command): 53 runs, 140 assertions, 0 failures.
- `rubocop bin lib test`: 9 files, no offenses.
- `clang-format --dry-run --Werror` on `keymap.c` and `config.h`: clean.
- `cspell` on every changed file: 27 files, 0 issues.
- `qmk compile -kb keyboardio/model100 -km eirvandelden` (QMK at `2c745388201b633ba04036b17157669632d1740a`, the keg-only compilers on `PATH`): exits 0.
- `bin/keymap-parity`: exits 0 and prints nothing.
- `git diff --exit-code origin/main -- Model01 Model100 Chrysalis_Keyboardio-Model-100_layout.json`: exits 0.
- The plan's Caps Word and Autocorrect `grep`: exits 1.

Bugs pass: the code changes hold. `get_flow_tap_term()` repeats QMK's weak default (`quantum/action_tapping.c:1099`) for every key except the Shift mod-taps. `QK_MOD_TAP_GET_MODS(keycode) & MOD_LSFT` matches both `LSFT_T` (`0x02`) and `RSFT_T` (`0x12`), and none of the Ctrl, Alt or Cmd mod-taps in the keymap. The generated `info_config.h` enables 29 effects, and `config.h` turns off 27 of them with `#undef`. The link map holds only `BREATHING`, `CYCLE_LEFT_RIGHT` and `SOLID_REACTIVE_SIMPLE`, plus the always-built solid colour and the custom `lights_off`, so the cycle is as the plan says. The port sets `RGB_MATRIX_DEFAULT_MODE`, but not `keyboard_post_init_*`, so the keymap's `keyboard_post_init_user()` does not collide with it. The Spotlight exception is still an exact pair, and `KC_MCTL` at that position is now reported.

Security pass: nothing found. No new external input.

Compliance: criteria 1–3 and 12 are proven by the runs above. Criteria 4–11 wait on the keyboard; the checklist now has 9 lines ticked. The way-back `.bin` (spec requirement 12) is still not recorded as kept. The plan's three additions of 2026-10-02 replace spec requirement 5's `KC_MCTL` exception and requirement 11's port-default lights, and the plan records both as Etienne's choice. Two tests named in `plan.md` `## Proof` were renamed, not weakened; see the nit below. No test was skipped or deleted. The branch is 9 commits ahead of its `origin` branch.

- [x] Important: The plan's proof for the Shift change is "typing `people` still fires no modifier", but the `people` tick comes from `dafa43d`, before the change in `075d6eb`. With the Shift keys out of Flow Tap, a fast opposite-hand roll that presses and releases a key while `p` or `g` is still down now becomes Shift under Permissive Hold, so the earlier tick does not cover it. Re-type `people` after the change, and add a check for fast opposite-hand rolls from both Shift keys, such as `graph` and `good` — `docs/changes/8-move-the-model-100-to-qmk-firmware/keyboard-checklist.md:80` fixed (Check fast opposite-hand rolls from the Shift keys and the toggle from a fresh start)
- [x] Important: The guide's "Dual-use timing" section says the keymap's `config.h` "holds exactly this" (three lines), and that Flow Tap keeps the top-row modifiers from firing while typing. `config.h` now also holds 29 light settings, and `get_flow_tap_term()` takes both Shift keys out of Flow Tap. The `word?` reason is in `plan.md` only, and the plan's doc step asks the guide to describe what the keymap uses and why. The guide also does not say that the lights start off and cycle through four effects plus off — `docs/qmk-migration.md:153` fixed (Describe the Shift keys outside Flow Tap, the lights and the kept way-back file in the guide)
- [x] Nit: `plan.md` `## Proof` still names `test_mission_control_position_is_allowed_to_differ` and `test_a_different_key_at_the_mission_control_position_is_reported`. Both were renamed for Spotlight in `comparison_test.rb`. The `bin/keymap-parity` paragraph (exception `0x2A2` against `KC_MCTL`) and the Mission Control risk also still describe the old exception. Update the names, or say in the 2026-10-02 addition that they replace these lines — `docs/changes/8-move-the-model-100-to-qmk-firmware/plan.md:163` fixed (Point the plan's Proof at the Spotlight test names)
- [x] Nit: The keyboard now starts in the `lights_off` effect, so "LED toggle turns the lights off and on" shows nothing after a fresh plug-in. Say to press LED next first — `docs/changes/8-move-the-model-100-to-qmk-firmware/keyboard-checklist.md:90` fixed (Check fast opposite-hand rolls from the Shift keys and the toggle from a fresh start)

## Round 7 — 2026-10-02T09:53Z — f10a890

Scope: `origin/main...HEAD` (53 commits, 27 files), with focus on the 8 commits since round 6 (`f9675da..f10a890`): the round 6 fixes, the way-back `.bin` recorded as kept, and the custom 5-second `key_fade` effect. The working tree is clean. There is no `REVIEW.md`, so the default passes ran: Bugs, Security, Compliance.

Run on this machine:

- Minitest (the plan's command): 53 runs, 140 assertions, 0 failures.
- `rubocop bin lib test`: 9 files, no offenses.
- `clang-format --dry-run --Werror` on `keymap.c` and `config.h`: clean.
- `cspell` on every changed file: 27 files, 0 issues.
- `qmk compile -kb keyboardio/model100 -km eirvandelden` (QMK at `2c745388201b633ba04036b17157669632d1740a`, the keg-only compilers on `PATH`): exits 0.
- `bin/keymap-parity`: exits 0 and prints nothing.
- `git diff --exit-code origin/main -- Model01 Model100 Chrysalis_Keyboardio-Model-100_layout.json`: exits 0.
- The plan's Caps Word and Autocorrect `grep`: exits 1.
- `shasum -a 256 ~/Documents/keyboardio/model100-kaleidoscope-1ee038c.bin` matches the SHA-256 in the guide.

Bugs pass: the round 6 fixes hold. `RGB_MATRIX_KEYPRESSES` alone defines `RGB_MATRIX_KEYREACTIVE_ENABLED` (`quantum/rgb_matrix/rgb_matrix_types.h:26`), so `g_last_hit_tracker` still exists without `SOLID_REACTIVE_SIMPLE`. `key_fade_elapsed()` walks the hits newest first, so a key pressed twice uses its last press. The `int8_t` index is safe for 64 hits, and the brightness sum stays in 0–255. One QMK behaviour shortens the fade; see the nit below.

Security pass: nothing found. No new external input.

Compliance: criteria 1–3 and 12 are proven by the runs above. Spec requirement 12 now holds: the way-back `.bin` exists, and its hash matches the guide. Criteria 4–11 wait on the keyboard; the checklist has 12 lines ticked and 38 open. The plan's 2026-10-02 fade addition says to drop `SOLID_REACTIVE_SIMPLE`, and `config.h` follows it. No test was added, weakened, skipped or deleted in these commits. The branch is 18 commits ahead of its `origin` branch.

- [x] Important: The guide's "Lights" section still describes the lights before the fade change. It says the keymap keeps key-press fade as `SOLID_REACTIVE_SIMPLE`, which `config.h` no longer enables. It says the LED key cycles "solid colour, breathing, rainbow wave, key-press fade and off". The plan and the checklist say off comes before the fade, and LED next from start-up goes to the fade. It does not name the custom `key_fade` effect, its 5 seconds, or `LED_HITS_TO_REMEMBER 64` — `docs/qmk-migration.md:181` fixed (Describe the custom 5-second key-press fade in the guide)
- [x] Nit: QMK wipes the whole hit buffer when its oldest hit reaches about 65.5 s. In `rgb_task_timers()` (`quantum/rgb_matrix/rgb_matrix.c:288`), an overflowing tick decrements `count` but stays at index 0, so each frame drops one more hit, newest first. With 64 hits remembered, fewer than 64 presses in 65 s is ordinary slow typing. The keys pressed in the last 5 s then go dark at once, about once a minute. With 8 hits this needed fewer than 8 presses in 65 s. The ticked check types a fast sentence, so it does not show this. A per-LED last-press time from `timer_read32()`, kept by the keymap, would avoid the shared buffer. At the least, add a checklist line that types slowly for over a minute — `keyboards/keyboardio/model100/keymaps/eirvandelden/rgb_matrix_user.inc:17` fixed (Time the key-press fade from each key's own last press)

## Round 8 — 2026-10-02T09:57Z — 225e8a5

Scope: `origin/main...HEAD` (58 commits, 27 files), with focus on the 5 commits since round 7 (`f10a890..225e8a5`): the per-key press times for the key-press fade, and the guide's "Lights" section. The working tree is clean. There is no `REVIEW.md`, so the default passes ran: Bugs, Security, Compliance.

Run on this machine:

- Minitest (the plan's command): 53 runs, 140 assertions, 0 failures.
- `rubocop bin lib test`: 9 files, no offenses.
- `clang-format --dry-run --Werror` on `keymap.c` and `config.h`: clean.
- `cspell` on every changed file: 27 files, 0 issues.
- `qmk compile -kb keyboardio/model100 -km eirvandelden` (QMK at `2c745388201b633ba04036b17157669632d1740a`, the keg-only compilers on `PATH`): exits 0, no warnings.
- `bin/keymap-parity`: exits 0 and prints nothing.
- `git diff --exit-code origin/main -- Model01 Model100 Chrysalis_Keyboardio-Model-100_layout.json`: exits 0.
- The plan's Caps Word and Autocorrect `grep`: exits 1.

Bugs pass: the round 7 fixes hold. `LED_HITS_TO_REMEMBER` still defaults to 8 without `RGB_MATRIX_KEYPRESSES` (`quantum/rgb_matrix/rgb_matrix_types.h:31`, outside any `#ifdef`), so the `leds` buffer in `remember_press()` compiles and holds the at most 1 LED the Model 100 maps per key. `pre_process_record_user()` runs from `action_exec()` before `action_tapping_process()` (`quantum/action.c:133`), so each physical press is timed once, also for the tap-hold keys, and the tapping buffer's replays do not time it again. The keyboard defines no `pre_process_record_kb()` that could skip the user hook. `timer_read32() | 1` keeps a press at tick 0 apart from "never". The guide's new effect order matches QMK's: custom user effects follow the built-in ones, `lights_off` before `key_fade`.

Security pass: nothing found. No new external input.

Compliance: criteria 1–3 and 12 are proven by the runs above. Criteria 4–11 wait on the keyboard; the checklist has 12 lines ticked and 39 open, including the new slow-typing line. The plan's round 7 addition says to drop `RGB_MATRIX_KEYPRESSES` and `LED_HITS_TO_REMEMBER`, and `config.h` follows it. No test was added, weakened, skipped or deleted in these commits. The branch is 23 commits ahead of its `origin` branch.

- [x] Nit: A key's press time is never cleared, and `timer_elapsed32()` wraps after 2^32 ms, about 49.7 days. A key last pressed about 49.7 days ago, with the keyboard powered all that time, gets an elapsed time near 0 again and lights for 5 s with no press. Rare keys, such as the palm or LED keys, are the likely ones. Fix: when `key_fade_elapsed()` reaches `KEY_FADE_MS`, set the press time back to 0, for example through a `key_fade_forget(led)` beside `key_fade_pressed_at()` — `keyboards/keyboardio/model100/keymaps/eirvandelden/rgb_matrix_user.inc:24` fixed (Forget a key's press once its fade has finished)
- [x] Nit: `remember_press()` sizes its buffer with `LED_HITS_TO_REMEMBER`, the size of the shared hit list that the comment above it says the fade no longer uses. QMK does the same in `process_rgb_matrix()`, so it is correct, but it reads as if the shared list is still involved. A local `#define` with a one-line reason, or a short comment, makes the intent clear — `keyboards/keyboardio/model100/keymaps/eirvandelden/keymap.c:67` fixed (Forget a key's press once its fade has finished)

## Round 9 — 2026-10-02T10:05Z — 7e99b8b

Scope: `origin/main...HEAD` (60 commits, 27 files), with focus on the 2 commits since round 8 (`1b7e12f..7e99b8b`): the press time cleared once its fade has finished, and the comment on the press buffer's size. The working tree is clean. There is no `REVIEW.md` or `REVIEW.local.md`, so the default passes ran: Bugs, Security, Compliance.

Run on this machine:

- Minitest (the plan's command): 53 runs, 140 assertions, 0 failures.
- `rubocop bin lib test`: 9 files, no offenses.
- `clang-format --dry-run --Werror` on `keymap.c` and `config.h`: clean.
- `cspell` on every changed file: 27 files, 0 issues.
- `qmk compile -kb keyboardio/model100 -km eirvandelden` (QMK at `2c745388201b633ba04036b17157669632d1740a`, the keg-only compilers on `PATH`): exits 0, no warnings.
- `bin/keymap-parity`: exits 0 and prints nothing.
- `git diff --exit-code origin/main -- Model01 Model100 Chrysalis_Keyboardio-Model-100_layout.json`: exits 0.
- The plan's Caps Word and Autocorrect `grep`: exits 1.

Bugs pass: the round 8 fixes hold while the fade is the active effect. `key_fade_elapsed()` now lives in `keymap.c` beside `pressed_at`, has external linkage, and `rgb_matrix_user.inc` declares it with the same signature. Its `uint16_t` return holds at most `KEY_FADE_MS` (5000). `KEY_FADE_MS` moved to `config.h`, which both `keymap.c` and the effect file see. The LED index passed in stays below `RGB_MATRIX_LED_COUNT`, the size of `pressed_at`. The clearing only runs inside the effect, so it does not cover the other effects; see the nit below.

Security pass: nothing found. No new external input.

Compliance: criteria 1–3 and 12 are proven by the runs above. Criteria 4–11 wait on the keyboard; the checklist is unchanged since round 8. No test was added, weakened, skipped or deleted in these commits. The branch is 26 commits ahead of its `origin` branch.

- [x] Nit: `plan.md`'s round 7 addition still says `key_fade_pressed_at()` hands the press time to the effect and that `key_fade` reads it. That function is gone: `key_fade_elapsed()` in `keymap.c` now computes the elapsed time and clears finished presses. The round 8 change has no plan line, and `KEY_FADE_MS` moved from `rgb_matrix_user.inc` to `config.h`. Add a short round 8 addition, or update the round 7 lines — `docs/changes/8-move-the-model-100-to-qmk-firmware/plan.md:87` fixed (Describe the fade timing as built in the plan)
- [x] Nit: Press times are only cleared while `key_fade` runs. In any other effect, in `lights_off` (the start-up effect), or with the lights toggled off, QMK does not call the effect (`quantum/rgb_matrix/rgb_matrix.c:324`), so presses keep their times. A key pressed about 49.7 days earlier still lights for up to 5 s if the fade is switched on in that 5-second window. This is far rarer than the round 8 case. Clearing in `remember_press()` cannot help, so the choices are to accept it with a word in the comment above `key_fade_elapsed()`, or to clear finished times from a `housekeeping_task_user()` sweep — `keyboards/keyboardio/model100/keymaps/eirvandelden/keymap.c:62` dismissed: it needs about 49.7 days of uptime and switching into the fade inside one 5-second window, and the result is one key glowing for up to 5 seconds; not worth extra code in a keymap

<!-- cspell:words Ilib Itest rubocop Werror LSFT RSFT KEYREACTIVE -->

## Round 10 — 2026-10-07T19:27Z — 6203a2b

Scope: `origin/main...HEAD` (66 commits, 27 files), with focus on the 3 commits since round 9 (`873a937..6203a2b`): round 9 closed, the plan's fade lines updated, the checklist's first-day findings, and the 2026-10-05 decision to keep QMK. No code changed since round 9. The working tree is clean. There is no `REVIEW.md` or `REVIEW.local.md`, so the default passes ran: Bugs, Security, Compliance.

Run on this machine:

- Minitest (the plan's command): 53 runs, 140 assertions, 0 failures.
- `rubocop bin lib test`: 9 files, no offenses.
- `clang-format --dry-run --Werror` on `keymap.c` and `config.h`: clean.
- `qmk compile -kb keyboardio/model100 -km eirvandelden` (QMK at `2c745388201b633ba04036b17157669632d1740a`, the keg-only compilers on `PATH`): exits 0.
- `bin/keymap-parity`: exits 0 and prints nothing.
- `git diff --exit-code origin/main -- Model01 Model100 Chrysalis_Keyboardio-Model-100_layout.json`: exits 0.
- The plan's Caps Word and Autocorrect `grep`: exits 1.
- `shasum -a 256 ~/Documents/keyboardio/model100-kaleidoscope-1ee038c.bin` matches the SHA-256 in the guide.
- `cspell` did not run. It left the toolchain on 2026-10-07 (dotfiles #180) and is not on `PATH`. See the nit below.

Bugs pass: nothing found. No code changed since round 9. The plan's round 7 addition now describes `key_fade_elapsed()`, the clearing of finished presses and `KEY_FADE_MS` in `config.h` as built. The checklist's light finding matches the effect order from start-up: off, key-press fade, solid colour, breathing, rainbow wave.

Security pass: nothing found. No new external input.

Compliance, `intent.md`'s Success list against the proof:

| Success item | Proof |
|---|---|
| Every key on every layer checked once | not met: "Every key, every layer" has 5 of 28 lines ticked |
| A week of normal work without a reason to go back | not met: cut short after three days (2026-10-02 to 2026-10-05), recorded in the checklist only |
| Going back to Kaleidoscope tried once and works | not met: all 3 "Way back tried" lines are open, recorded as "Not tried" |
| The firmware builds on my machine from this repository | met: `qmk compile` above |

Spec criteria 1–3 and 12 hold, as the runs above prove. The checklist has 16 lines ticked and 35 open. No test was added, weakened, skipped or deleted in these commits. The branch is 2 commits ahead of its `origin` branch, and pull request #12 is open.

- [x] Important: The way back to Kaleidoscope was never tried. `intent.md` lists it as a Success item, and spec criterion 10 and the plan's Proof 10 require it. The checklist now says "Not tried", but `intent.md` and `plan.md` still require it. Earlier changes of course (QMK default timing, Spotlight) got a dated plan addition with Etienne's choice; this one did not. After the follow-up branch removes the sketch and the Chrysalis layout, an untried `.bin` is the whole way back. Try it once, or record in a dated plan addition that criterion 10 is waived and why — `docs/changes/8-move-the-model-100-to-qmk-firmware/keyboard-checklist.md:110` → fixed (docs: record merging after three days, and what was left open); trying it is a prerequisite of the Kaleidoscope removal issue
- [x] Important: Two more Success items are not met, and only the checklist says so. The week of normal work ended after three days, and the every-key pass (criterion 4) has 5 of 28 lines ticked. The plan's risk line still says the pull request "merges only after the week passes", and Proof 4 and 11 point at open boxes. The on-keyboard proofs of two later plan additions are also open: the light cycle from start-up (the findings call it fixed, but its box is open) and the round 7 slow-typing fade check. Those changes have only compile proof so far. Finish the open checks, or add a dated plan addition that records the 2026-10-05 decision and the criteria it waives — `docs/changes/8-move-the-model-100-to-qmk-firmware/plan.md:129` → fixed (docs: record merging after three days, and what was left open)
- [x] Nit: The guide's status line still says "updated 2026-10-01" and "Nothing has been flashed yet". The keymap was flashed on 2026-10-02 and kept on 2026-10-05. The plan's doc step asks the guide to say what has been built and flashed. Step 3 of "Proposed order of work" also stops at "compile" — `docs/qmk-migration.md:5` → fixed (Say in the guide that the keymap is flashed and kept)
- [x] Nit: The branch still adds `cspell.yml` and `project-dictionary.txt`, but cspell left the toolchain on 2026-10-07 and nothing runs it. The plan's step 10 and its `project-dictionary.txt` line also still name cspell. Remove both files before the merge, with a plan line for it. The `cspell:words` comments in `plan.md` and this file leave with the change folder — `cspell.yml:1` → fixed (Remove the cspell config, which nothing runs any more)
