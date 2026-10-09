# Plan: Stray Ctrl+Cmd chords when typing "claude"

From `intent.md` (2026-10-09). Status: accepted.

## Context

Typing `claude` at once on the Model100, straight after a pause, sends `a` and `u` as Ctrl+Cmd chords and drops `c` and `l`. The keymap is `keyboards/keyboardio/model100/keymaps/eirvandelden/keymap.c` with `PERMISSIVE_HOLD`, `CHORDAL_HOLD` and `FLOW_TAP_TERM 150` in `config.h`. QMK is the fork `eirvandelden/qmk_firmware` at the pinned commit `2c74538`, cloned at `~/Developer/qmk_firmware`.

Root cause, read from `quantum/action_tapping.c` at the pinned commit (`process_tapping()`, `waiting_buffer_find_chordal_hold_tap()`):

- `-`, the last key before `claude`, is `DV_MINS` (`KC_QUOT`). That is not a Flow Tap key, and a pause longer than 500 ms switches Flow Tap off as well. So `c` (`RGUI_T(DV_C)`) starts undecided.
- `l` (`RCTL_T(DV_L)`) is pressed while `c` is undecided. It is a tap-hold key, so Chordal Hold does not settle `c` yet; `l` waits in the buffer.
- `a` (left hand) is pressed and released while `c` and `l` are still down. Permissive Hold then settles `c` as held without asking Chordal Hold about `c` → `l`. `waiting_buffer_find_chordal_hold_tap()` sees `l` → `a` as an opposite-hand chord and settles `l` as held too. `a` and `u` go out with Ctrl+Cmd.
- QMK documents this as intended: "Chordal Hold supports combining multiple same-side modifiers within the tapping term" (`docs/tap_hold.md`). QMK's own test `three_mod_taps_two_left_one_right` in `tests/tap_hold_configurations/chordal_hold/permissive_hold_flow_tap/` shows the same mechanism with three mod-taps and a different release order. It is supporting evidence only; this plan's own fast and slow regression tests prove the exact `c l a u` fault.
- Mid-word, Flow Tap settles `c` as a tap because a letter came less than 150 ms before it. That is why the fault shows only after a pause, such as opening a pane.

Facts checked while planning (2026-10-09):

- QMK's host test framework builds and runs on this Mac against the pinned checkout. `make -r -R -C ~/Developer/qmk_firmware -f builddefs/build_test.mk TEST=<name> TEST_OUTPUT=<name> TEST_PATH=<path relative to qmk_home> FULL_TESTS=<name> VERBOSE=false COLOR=false SILENT=false` builds `.build/test/<name>.elf`. An absolute `TEST_PATH` fails ("No rule to make target"). A `TEST_PATH` that climbs out with `..` puts object files outside `.build/`, so the runner keeps the test folder inside `.build/`.
- `qmk compile` run from a directory with a `qmk.json` uses that directory as userspace (`ORIG_CWD` in `lib/python/qmk/userspace.py`), before `user.overlay_dir`. `user.overlay_dir` still points at the `8-move-the-model-100-to-qmk-firmware` worktree; this plan does not change it.
- herdrdev/herdr#5017 merged on 2026-10-07 (`a124eed`). The newest stable release is still v0.9.3 (2026-09-29). Homebrew offers 0.9.3.
- `shellcheck`, `clang-format` and `rubocop` are installed. `cpplint` is not.
- No `.github/` folder, so no pull request template.

## Design decisions

1. **Same-hand roll rule.** Two mod-tap presses in a row on the same hand, where the first mod-tap is still held when the second one goes down, are a roll. A plain key or a layer key held before a mod-tap is not a roll, so a held palm layer key plus a mod-tap plus an opposite-hand key still chords. Both keys of a roll lose Permissive Hold until their next press: each one becomes a tap on release, or a hold only once the tapping term (200 ms) runs out. Chordal Hold and Flow Tap stay as they are.
   - Implementation: `PERMISSIVE_HOLD` becomes `PERMISSIVE_HOLD_PER_KEY`. `get_permissive_hold()` returns `!rolled(record->event.key)`: false for a key marked as rolled, true for every other key. The `true` matters: QMK's default `get_permissive_hold()` returns false, which would switch Permissive Hold off for every key. A press tracker, fed from `pre_process_record_user()` (which QMK calls in raw press order, before tap-hold processing), keeps one bit per matrix position (`matrix_row_t rolled[MATRIX_ROWS]`) plus the last pressed key, whether it is a mod-tap (`IS_QK_MOD_TAP`) and whether it is still held. Every press clears its own bit and becomes the last pressed key; a mod-tap press sets both bits when the last pressed key is a still-held mod-tap on the same hand.
   - Why both keys: marking only `c` fixes the case above when `l` comes within 150 ms of `c`, because Flow Tap then settles `l` as a tap. A slower roll leaves `l` undecided with `a` nested inside it, and Permissive Hold would make `l` a Control. Marking `l` as well closes that gap.
   - Rejected: overriding `get_chordal_hold()` alone. QMK does not consult it for the undecided key in the Permissive Hold branch, so `c` would still be held (worked through against the code).
   - Rejected: Hold On Other Key Press, a longer `FLOW_TAP_TERM`, or a Flow Tap term for the first key after a pause. Each one changes deliberate chords or ordinary typing more widely than this rule.
   - Trade-off, as the intent accepts: a deliberate same-hand multi-mod chord (for example `c` + `l` + left `a` for Ctrl+Cmd+A) now needs both keys held past the tapping term before the other hand presses. Single-mod opposite-hand chords (`c` + left `a`, `l` + left `a`) are unchanged.
2. **Tap-hold code moves to its own file**, `tap_hold.c` with `tap_hold.h`, in the keymap folder, added with `SRC += tap_hold.c` in `rules.mk`. It holds `chordal_hold_handedness()`, `is_shift_mod_tap()`, `get_flow_tap_term()`, `get_permissive_hold()` and the press tracker. `keymap.c` keeps the layers and the lights, and its `pre_process_record_user()` calls the tracker next to `remember_press()`. Reason: the host test can compile `tap_hold.c` as is; `keymap.c` cannot build outside the Model100 (its `LAYOUT`, RGB matrix calls). The move is its own commit, before any behaviour change.
3. **Host regression tests in this repository.** `test/tap_hold/` holds a QMK gtest suite (`config.h`, `test.mk`, `test_keymap.c`, `test_tap_hold.cpp`). `bin/tap-hold-test` copies that folder, the keymap's `tap_hold.c`, `tap_hold.h` and `config.h` (as `keymap_config.h`) into `<qmk_home>/.build/keyboardio_config_tap_hold/`, builds with the `make` line above, and runs the `.elf`. The test `config.h` includes `test_common.h` and then `keymap_config.h`, so the test always runs with the keymap's real tap-hold settings. Test matrix is QMK's 4×10; `chordal_hold_handedness()` splits it at `MATRIX_ROWS / 2`, so rows 0–1 are the left hand and rows 2–3 the right hand.
4. **Left-side modifiers.** In `keymap.c`: `RSFT_T(DV_G)` → `LSFT_T(DV_G)`, `RGUI_T(DV_C)` → `LGUI_T(DV_C)`, `RCTL_T(DV_L)` → `LCTL_T(DV_L)`; `RSFT_T(DV_7)` → `LSFT_T(DV_7)`, `RGUI_T(DV_8)` → `LGUI_T(DV_8)`, `RCTL_T(DV_0)` → `LCTL_T(DV_0)`; `RGUI_T(DV_EQL)` → `LGUI_T(DV_EQL)`. The plain `KC_RSFT` thumb key is not dual-use and stays. `LALT_T(DV_R)` and `LALT_T(DV_9)` already send left Alt. `is_shift_mod_tap()` matches `MOD_LSFT` and keeps working.
5. **`bin/keymap-parity` learns one narrow exception**: on any layer, a Chrysalis dual-use key with a right-side modifier matches a QMK mod-tap with the same tap key and the left-side variant of that modifier. Nothing else is relaxed. The Chrysalis layout stays unchanged, as the intent requires. Without this, the parity check would report seven differences for good. The `c2json` fixture is regenerated from the new `keymap.c`, so the existing real-data test exercises the exception.
6. **Left-side modifiers get their own test**, not only the parity check, because the parity exception would also pass if the keymap still sent right-side modifiers. `test/keymap_parity/qmk_keymap_test.rb` reads the regenerated `c2json.json` fixture and asserts the descriptor at each of the seven positions is a mod-tap with the left-side modifier.
7. **On-keyboard checks** go in `docs/changes/stray-modifiers-when-typing-claude/keyboard-checklist.md`, one tick box per acceptance criterion, as PR #12 did. Flashing needs `Prog` held while plugging in, and the checks need typing, so Etienne does both.
8. **herdr.** At the end of implementation, check for a stable herdr release that contains `a124eed`. Upgrade only then, with `brew upgrade herdr`, never the preview channel.

## Integration points

- QMK at the pinned commit: `quantum/action_tapping.c` (Permissive Hold per key, Chordal Hold, Flow Tap), `quantum/action.c` (`pre_process_record_quantum()` before `action_tapping_process()`), and the host test framework (`builddefs/build_test.mk`, `tests/test_common/`). Nothing in the QMK checkout changes; the runner writes only inside its gitignored `.build/`.
- `bin/keymap-parity` and `lib/keymap_parity/comparison.rb`.
- herdr from Homebrew (0.9.3).
- The pull request stacks on `8-move-the-model-100-to-qmk-firmware` (PR #12).

## Files that change

- `keyboards/keyboardio/model100/keymaps/eirvandelden/tap_hold.c` (new) — the tap-hold callbacks moved from `keymap.c`, plus the press tracker (`tap_hold_track_press(keyrecord_t*)` or a similar intention-revealing name) and `get_permissive_hold()`.
- `keyboards/keyboardio/model100/keymaps/eirvandelden/tap_hold.h` (new) — declares the tracker for `keymap.c` and the test keymap.
- `keyboards/keyboardio/model100/keymaps/eirvandelden/keymap.c` — tap-hold callbacks removed; `pre_process_record_user()` also calls the tracker; seven mod-taps switch to left-side modifiers (design decision 4).
- `keyboards/keyboardio/model100/keymaps/eirvandelden/config.h` — `#define PERMISSIVE_HOLD` becomes `#define PERMISSIVE_HOLD_PER_KEY`.
- `keyboards/keyboardio/model100/keymaps/eirvandelden/rules.mk` — `SRC += tap_hold.c`.
- `test/tap_hold/config.h`, `test.mk`, `test_keymap.c`, `test_tap_hold.cpp` (new) — the host regression suite. From step 4 on, `test_keymap.c` defines `pre_process_record_user()` calling the tracker, as `keymap.c` does; the step 2 version has no such callback, so the first test links and fails on its reports. Keycodes match `keymap.c` (`LGUI_T(DV_C)` and so on, through `keymap_extras/keymap_dvorak.h`; if the test build cannot find that header, use the `KC_` equivalents with a comment naming the Dvorak letter).
- `bin/tap-hold-test` (new, bash, `set -euo pipefail`) — the runner from design decision 3. Reads `qmk_home` from `qmk config user.qmk_home`. Passes its arguments on to the `.elf` (for `--gtest_filter`). Exit status is the test binary's.
- `lib/keymap_parity/comparison.rb` — the left-side exception (design decision 5).
- `test/keymap_parity/comparison_test.rb` — tests for that exception.
- `test/keymap_parity/qmk_keymap_test.rb` — the left-side modifier test from design decision 6.
- `test/keymap_parity/fixtures/c2json.json` — regenerated with `qmk c2json -kb keyboardio/model100 -km eirvandelden --no-cpp <absolute path to keymap.c>`.
- `docs/qmk-migration.md` — the "Dual-use timing" and "Opposite-hands rule: Chordal Hold" sections: `PERMISSIVE_HOLD_PER_KEY`, the same-hand roll rule and why, the multi-mod trade-off, the left-side modifiers, the move to `tap_hold.c`, and how to run `bin/tap-hold-test`.
- `docs/changes/stray-modifiers-when-typing-claude/keyboard-checklist.md` (new) — the on-keyboard checks (design decision 7).

Not changed: `Model01/`, `Model100/`, both Chrysalis layouts, `Chrysalis.pdf`, the QMK checkout and its `user.overlay_dir` setting, the Kaleidoscope fork, Etienne's dotfiles.

## Order of work

0. In this worktree, rebase on `8-move-the-model-100-to-qmk-firmware` if it has moved (playbook rule 20).
1. Move the tap-hold callbacks from `keymap.c` into `tap_hold.c`/`tap_hold.h` and add `SRC += tap_hold.c`. No behaviour change. Prove it: `qmk compile -kb keyboardio/model100 -km eirvandelden` from the worktree root succeeds, and the build log shows `tap_hold.c` compiled from this worktree. Commit.
2. Write `bin/tap-hold-test` and `test/tap_hold/` with the first acceptance test, `ClaudeRollAfterPauseTypesLetters` (below). `test_keymap.c` does not call the tracker yet, since the tracker does not exist; the test must link and fail because its reports carry modifiers, not on a missing symbol. This is the walking skeleton. Commit the runner and the failing test.
3. Add the remaining host tests from `## Proof`, each run and watched fail where it covers new behaviour (`ClaudeRollSlowSecondKeyTypesLetters`, `CmdChordSendsLeftGui`, `CtrlChordSendsLeftCtrl`), or pass where it guards existing behaviour.
4. Implement the press tracker and `get_permissive_hold()` in `tap_hold.c`, switch `config.h` to `PERMISSIVE_HOLD_PER_KEY`, and wire the tracker into `pre_process_record_user()` in `keymap.c`. Add the `pre_process_record_user()` callback to `test_keymap.c`. Run `bin/tap-hold-test` until green. Commit.
5. Write the failing tests in `test/keymap_parity/comparison_test.rb` for the left-side exception, and the left-side modifier test in `test/keymap_parity/qmk_keymap_test.rb` (red until the fixture is regenerated). Then switch the seven mod-taps in `keymap.c` to left-side modifiers, add the exception to `comparison.rb`, regenerate `c2json.json`, and run the Ruby suite and `bin/keymap-parity` (exit 0). The host test keymap already uses left-side keycodes from step 2. Commit the keymap switch and the parity exception as separate commits if the tests allow it.
6. Build with `qmk compile -kb keyboardio/model100 -km eirvandelden` from the worktree root. Lint: `clang-format --dry-run --Werror` on `keymap.c`, `tap_hold.c`, `tap_hold.h`, `config.h` and the files in `test/tap_hold/`; `shellcheck bin/tap-hold-test`; `rubocop bin lib test`. Fix every finding without disable comments.
7. Update `docs/qmk-migration.md` and write `keyboard-checklist.md`. Commit.
8. herdr: run `gh release list -R herdrdev/herdr` and, for any stable tag newer than v0.9.3, `gh api repos/herdrdev/herdr/compare/a124eed...<tag> --jq .status` (`ahead` or `identical` means the tag contains #5017). Check that Homebrew offers that version (`brew info herdr`). Only then run `brew upgrade herdr`. Otherwise leave 0.9.3 and record that in the delivery account.
9. Hand Etienne the firmware and `keyboard-checklist.md`: `qmk flash -kb keyboardio/model100 -km eirvandelden` from the worktree root, with `Prog` held while plugging in. Record his results in the checklist. A failed check goes back to step 3 with a new host test that reproduces it.
10. Before opening the pull request against `8-move-the-model-100-to-qmk-firmware`: if that branch still has commits that are not on `origin`, stop and ask Etienne (intent constraint).

## Risks

- **The rule misjudges a real chord.** A deliberate same-hand multi-mod chord inside 200 ms now types letters. The intent accepts this; `docs/qmk-migration.md` says how to chord past the tapping term instead.
- **A plain key before a mod-tap is not covered.** A slow roll from a plain same-hand key into a mod-tap with an opposite-hand key nested inside it can still make that mod-tap a hold. Fast rolls are covered by Flow Tap. This was chosen over marking any held same-hand key, which would break a held palm layer key plus a mod-tap chord.
- **Host tests do not run the real keymap layers.** They compile the real `tap_hold.c` and `config.h`, but the keycode positions come from `test_keymap.c`. The on-keyboard checklist covers the wiring in `keymap.c` and the real matrix.
- **QMK test build interface is internal.** `build_test.mk` and its variables are not a public API. The runner is pinned to the QMK commit in `docs/qmk-migration.md`; moving the pin means re-running `bin/tap-hold-test`.
- **Flow Tap interplay.** The fix relies on Flow Tap staying as is for mid-word typing. The `word?` Shift exception and mid-word Flow Tap get regression tests so the move to `tap_hold.c` cannot break them.
- **Pushing this branch publishes the base branch's local commits**, because they are its ancestors. The intent forbids pushing the base branch itself, not this one; step 10 still stops before the pull request.

## Proof

- Opening a new herdr pane with Ctrl+S, `-` and typing `claude` at once gives `claude`, five tries out of five → check: Etienne, on the flashed keyboard, in herdr, five tries, recorded in `keyboard-checklist.md`. Automated regression: `test/tap_hold/test_tap_hold.cpp` `ClaudeRollAfterPauseTypesLetters` and `ClaudeRollSlowSecondKeyTypesLetters`.
- In `cat -v`, after Enter and a one-second pause, typing `claude` fast shows `claude`, five tries out of five → check: Etienne, on the flashed keyboard, five tries, recorded in `keyboard-checklist.md`. Automated regression: `test/tap_hold/test_tap_hold.cpp` `ClaudeRollAfterPauseTypesLetters` (starts with a 1000 ms idle).
- Holding `c` and pressing `a` with the left hand selects all (Cmd+A) → `test/tap_hold/test_tap_hold.cpp` `CmdChordSendsLeftGui`; check: Etienne in a text field, recorded in `keyboard-checklist.md`.
- Holding `l` and pressing `a` with the left hand moves the zsh cursor to the start of the line (Ctrl+A) → `test/tap_hold/test_tap_hold.cpp` `CtrlChordSendsLeftCtrl`; check: Etienne in zsh, recorded in `keyboard-checklist.md`.
- A key-event viewer reports Left Shift, Left Command and Left Control while `g`, `c` and `l` are held, and for `7`, `8`, `0` on the numbers layer and `=` on the navigation layer → `test/keymap_parity/qmk_keymap_test.rb` `test_real_keymap_dual_use_keys_send_left_side_modifiers` (regenerated fixture), plus `bin/keymap-parity` exit 0; check: Etienne with a key-event viewer of his choice (none is installed; macOS has none built in), recorded in `keyboard-checklist.md`.
- Once herdr is upgraded, pressing Ctrl+Cmd+A in a plain zsh pane types no text; otherwise herdr stays at 0.9.3 and the delivery account says so → check: step 8's `gh` and `brew info herdr` output in the delivery account; if upgraded, Etienne's Ctrl+Cmd+A try in `keyboard-checklist.md`.

Per changed file, the unit tests expected, named as behaviour:

- `tap_hold.c` (through `test/tap_hold/test_tap_hold.cpp`):
  - `ClaudeRollAfterPauseTypesLetters` — after 1000 ms idle: `c`↓ `l`↓ `a`↓ `u`↓ 20 ms apart, then `a`↑ `u`↑ `c`↑ `l`↑; the reports type `c l a u` (HID `I P A F`) in that order and no report carries a modifier.
  - `ClaudeRollSlowSecondKeyTypesLetters` — as above, but `l` goes down 160 ms after `c` (past `FLOW_TAP_TERM`) and every key is released within the tapping term; still `c l a` without modifiers.
  - `CmdChordSendsLeftGui` — after 1000 ms idle, `c` held, left `a` pressed and released, `c` released: Left GUI + `A`, then nothing typed for `c`.
  - `CtrlChordSendsLeftCtrl` — the same with `l`, also after 1000 ms idle: Left Ctrl + `A`.
  - `HeldLayerKeyThenModTapStillChords` — a right-hand `MO()` key held, then `c` held, then left `a` pressed and released inside the tapping term: Left GUI + the layer's key at `a`, so a held layer key does not count as a roll.
  - `PlainKeyThenModTapIsNotARoll` — right `h` held, `c` pressed 160 ms later (past `FLOW_TAP_TERM`, so Flow Tap stays out), `h` released, left `a` nested inside `c`: Left GUI + `A` (only mod-tap pairs mark a roll).
  - `SameHandPairSettlesAsTap` — `c`↓ `h`↓ (right-hand plain key) gives `c h`, no modifier (Chordal Hold unchanged).
  - `SameHandModsHeldPastTappingTermStillChord` — `c`↓ `l`↓, idle past the tapping term, left `a` pressed and released: Left GUI + Left Ctrl + `A`.
  - `ShiftAfterLetterStillShifts` — a letter, then within 150 ms `p` (`LSFT_T(DV_P)`) held with right `/` pressed and released: Shift + `/`, no `p` (the `word?` fix).
  - `ModTapMidWordSettlesAsTap` — a letter, then `c` within 150 ms, held across a left-hand key: `c` typed at once (Flow Tap unchanged).
- `lib/keymap_parity/comparison.rb` (through `test/keymap_parity/comparison_test.rb`):
  - `test_right_side_dual_use_matches_left_side_mod_tap_with_same_tap_key`
  - `test_left_side_dual_use_against_right_side_mod_tap_is_reported`
  - `test_right_side_dual_use_against_left_side_mod_tap_with_other_tap_key_is_reported`
  - `test_right_side_dual_use_against_a_different_left_modifier_is_reported`
- `test/keymap_parity/qmk_keymap_test.rb`:
  - `test_real_keymap_dual_use_keys_send_left_side_modifiers` — table of the seven positions (base `g c l`, numbers `7 8 0`, navigation `=`), each a mod-tap with `:lsft`, `:lgui` or `:lctl`.

Test setup: host tests use QMK's `TestFixture`, `TestDriver` and `KeymapKey(layer, col, row, keycode)` with `idle_for()` and `run_one_scan_loop()`, through `bin/tap-hold-test`; they need `~/Developer/qmk_firmware` at the pinned commit and the host compiler, nothing else. Ruby tests: `ruby -Ilib -Itest -e 'Dir["test/**/*_test.rb"].each { require File.expand_path(it) }'`, no QMK needed.

## Out of scope

- The Model01, the Kaleidoscope sketch, the Chrysalis layouts, the Kaleidoscope fork and the QMK fork (including upstreaming the rule to QMK).
- The herdr preview channel or a build from master; Etienne's dotfiles.
- Changing `TAPPING_TERM`, `FLOW_TAP_TERM`, or the Shift keys' Flow Tap exception.
- Making the thumb `KC_RSFT` a left Shift; it is not dual-use.
- Pushing `8-move-the-model-100-to-qmk-firmware`.
- CI for the host tests (issue #10 covers a CI build).

---
Domain skills applied: None (QMK C firmware and a small Ruby tool; the Rails skills do not apply). Playbook test-first, lint and commit rules applied.

## Critique

### Round 1 (codex exec -p terra)

- Unrolled keys must return true from `get_permissive_hold()`, since QMK's per-key default is false and would switch Permissive Hold off for every key → fixed (design decision 1 states that unrolled keys return true, and why; the Cmd and Ctrl chord tests start after 1000 ms idle)
- The tracker was too broad: any held same-hand key, such as a palm layer key, would mark the next mod-tap and break a layer-plus-mod chord → fixed (a roll needs two consecutive same-hand mod-taps; added `HeldLayerKeyThenModTapStillChords` and `PlainKeyThenModTapIsNotARoll`; the risk entry now names the slow plain-key-then-mod-tap gap)
- The first host test could not fail for the right reason, because `test_keymap.c` called a tracker that only exists from step 4, so it would fail to link → fixed (the tracker callback joins `test_keymap.c` in step 4; step 2 says the test must fail on modifier reports)
- The parity exception would pass even if the seven keys still sent right-side modifiers, so it does not prove the switch → fixed (design decision 6 and `test_real_keymap_dual_use_keys_send_left_side_modifiers` in `qmk_keymap_test.rb` assert all seven positions)
- The plan overstated QMK's `three_mod_taps_two_left_one_right` test as asserting this exact sequence → fixed (Context calls it supporting evidence; the local fast and slow regressions are the proof)
