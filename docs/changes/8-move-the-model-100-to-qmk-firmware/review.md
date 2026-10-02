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

<!-- cspell:words Ilib Itest rubocop Werror -->
