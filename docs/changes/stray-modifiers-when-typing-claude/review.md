# Review: stray-modifiers-when-typing-claude

## Round 1 — 2026-10-09T20:58Z — d90b69a

No `REVIEW.md` or `REVIEW.local.md` in the repository; the reviewer's default Bugs, Security and Compliance passes apply. Base: `origin/main` (the stacked base #12 is already in it; `git log origin/main..HEAD` shows only this branch's 11 commits). No uncommitted changes.

Current state: `bin/tap-hold-test` 10/10 green; Ruby suite 59 runs, 0 failures; `bin/keymap-parity` exit 0; `rubocop bin lib test`, `shellcheck bin/tap-hold-test` and `clang-format --dry-run --Werror` on the keymap and test files are clean. `gh release list -R herdrdev/herdr` and `brew info herdr` confirm v0.9.3 is still the newest stable release.

Bugs: none found in the roll rule. Checked against the pinned QMK: `pre_process_record_quantum()` runs before `action_tapping_process()` in raw event order (`quantum/action.c:133`), and Permissive Hold is asked through `get_permissive_hold(tapping_keycode, &tapping_key)` (`quantum/action_tapping.c:234`), so the per-key bit reaches the undecided key.

Security: nothing found. `bin/tap-hold-test` guards its `rm -rf` with `${qmk_home:?}` and only touches a fixed folder under QMK's gitignored `.build/`.

Compliance, acceptance criteria against proof:

- herdr pane, `claude` five out of five → `ClaudeRollAfterPauseTypesLetters`, `ClaudeRollSlowSecondKeyTypesLetters`; on-keyboard check not yet ticked.
- `cat -v`, `claude` five out of five → `ClaudeRollAfterPauseTypesLetters`; on-keyboard check not yet ticked.
- Hold `c` + left `a` gives Cmd+A → `CmdChordSendsLeftGui`; on-keyboard check not yet ticked.
- Hold `l` + left `a` gives Ctrl+A → `CtrlChordSendsLeftCtrl`; on-keyboard check not yet ticked.
- Left Shift, Command and Control on the seven keys → `test_real_keymap_dual_use_keys_send_left_side_modifiers`, `test_real_keymap_has_no_right_side_dual_use_modifiers`, `bin/keymap-parity` exit 0; key-event viewer check not yet ticked.
- herdr Ctrl+Cmd+A types no text → not applicable: no stable release contains #5017, recorded in the plan's build notes.

Every test named in `plan.md`'s Proof exists: the ten host tests, the four `comparison_test.rb` tests and the `qmk_keymap_test.rb` test. No existing test was weakened, skipped or deleted.

- [ ] Important: every box in the keyboard checklist is still unticked, so the on-keyboard half of the first five acceptance criteria (five-out-of-five `claude` in herdr and `cat -v`, Cmd+A, Ctrl+A, left-side modifiers in a key-event viewer) has no evidence yet. Plan step 9 and §7a need these results before the pull request opens. — `docs/changes/stray-modifiers-when-typing-claude/keyboard-checklist.md:9` →
- [x] Nit: the build note says the left-side switch newly gives `g` and `7` the `word?` Shift exception because `is_shift_mod_tap()` matched only `MOD_LSFT`. That is wrong: `QK_MOD_TAP_GET_MODS(RSFT_T(...))` is `0x12`, and `0x12 & MOD_LSFT` is non-zero, so the right-side Shift keys already had the exception (as `docs/qmk-migration.md` said before this branch). Correct or remove the note so the delivery account does not claim a behaviour change that did not happen. — `docs/changes/stray-modifiers-when-typing-claude/plan.md:142` → fixed in e8fbd6a: the wrong Shift note is removed.
- [x] Nit: `test_real_keymap_dual_use_keys_send_left_side_modifiers` checks that each mod-tap appears somewhere on its layer (`assert_includes`), not at its position, as design decision 6 describes. A keymap that put `LGUI_T(DV_C)` on the wrong key would still pass this test; only `bin/keymap-parity` would catch it. — `test/keymap_parity/qmk_keymap_test.rb:66` → fixed in bd3b054: each key is checked at its layer, row and column; swapping `c` and `l` fails the test.
- [x] Nit: `is_rolled()` and `set_rolled()` index `rolled[key.row]` with no bounds check. `tap_hold_track_event()` sees every event, and QMK's virtual key locations (encoders 252/253, DIP switches 250/251) would read and write far past the array if one of those features is ever enabled. The Model100 keymap enables none today. — `keyboards/keyboardio/model100/keymaps/eirvandelden/tap_hold.c:42` → fixed in 098e018: the tracker ignores events past the matrix; `EventOutsideMatrixDoesNotBreakRoll` failed with Ctrl+Cmd first.
- [x] Nit: `tap_hold_track_event()` reads the keycode again with `get_record_keycode(record, false)`, which depends on the layer cache that `pre_process_record_quantum()` has just updated. `pre_process_record_user()` already receives that `keycode`; passing it in removes the hidden ordering dependency. — `keyboards/keyboardio/model100/keymaps/eirvandelden/tap_hold.c:64` → fixed in 12f3284: `tap_hold_track_event()` takes the keycode from `pre_process_record_user()`.
- [x] Nit: the test fixture uses `std::find` and `std::begin`/`std::end` without `<algorithm>` and `<iterator>`; it compiles only through transitive includes of the QMK test headers. — `test/tap_hold/test_tap_hold.cpp:43` → fixed in 68ee0f7: `<algorithm>` and `<iterator>` are included.

## Round 2 (Codex) — 2026-10-09 — d90b69a

Reviewer: `codex review --base origin/main`, transcribed by the coordinator.

Codex found no actionable defects in the changes. It ran `bin/keymap-parity`, which completed. It could not run `bin/tap-hold-test`: its sandbox refused to write into the QMK checkout's `.build/` folder outside the worktree. The coordinator ran `bin/tap-hold-test` outside the sandbox on the same commit: 10 tests passed.

No findings.

## Round 3 — 2026-10-09T21:37Z — 45189ad

No `REVIEW.md` or `REVIEW.local.md` in the repository; the reviewer's default Bugs, Security and Compliance passes apply. Base: `origin/main`, fetched before this round; `git log origin/main..HEAD` shows 19 commits. No uncommitted changes. This round re-reads the whole diff and the five fix commits since round 1 (`bd3b054`, `12f3284`, `098e018`, `68ee0f7`, `e8fbd6a`).

Current state: `bin/tap-hold-test` 11/11 green (the ten planned tests plus `EventOutsideMatrixDoesNotBreakRoll`); Ruby suite 59 runs, 0 failures; `bin/keymap-parity` exit 0; `qmk compile -kb keyboardio/model100 -km eirvandelden` builds with the documented compiler `PATH`; `clang-format --dry-run --Werror`, `shellcheck bin/tap-hold-test` and `rubocop bin lib test` are clean.

Bugs: none found. The round 1 fixes hold. Tick events never reach `pre_process_record_user()` (`IS_NOEVENT` guard, `quantum/action.c:133`), so the fake `(0, 0)` key of `MAKE_TICK_EVENT` cannot clear `last_press.is_down`. `chordal_hold_handedness()` splits the real 8×8 matrix (`keyboards/keyboardio/model100/config.h:22`) at row 4, and the test's 4×10 matrix at row 2, as the comments say. `set_rolled()` has no bounds check of its own, but only receives keys that passed `in_matrix()`.

Security: nothing found. The runner's `rm -rf` stays guarded by `${qmk_home:?}` and a fixed folder under QMK's `.build/`.

Compliance: every test named in `plan.md`'s Proof exists and passes. The build notes match the code (`quantum.h`, the `chordal_hold_layout` stub, `tap_hold_track_event(uint16_t, keyrecord_t*)` with the matrix guard, herdr at 0.9.3). No test was weakened, skipped or deleted. Round 1's Important finding is still open: no box in `keyboard-checklist.md` is ticked, so the on-keyboard half of the first five acceptance criteria still has no evidence.

- [x] Nit: the runner copies `tap_hold.h` only `if [ -f ... ]`, but `tap_hold.h` exists from step 1 and both `test_keymap.c` and `test_tap_hold.cpp` include it unconditionally, so the build fails without it anyway. Copy it like `tap_hold.c` and drop the branch. — `bin/tap-hold-test:18` → fixed in 2cd24be: `tap_hold.h` is copied with `tap_hold.c`.
- [x] Nit: `test/tap_hold/config.h` includes `keymap_config.h` before `test_common.h`; design decision 3 says `test_common.h` first, then the keymap's settings. The two headers share no macro today, so behaviour is the same, but the code and the plan disagree and the build notes do not record it. Swap the includes or add a build note. — `test/tap_hold/config.h:3` → fixed in d15cc44: `test_common.h` comes first, then the keymap's settings.

## Round 4 (Codex) — 2026-10-09 — 45189ad

Reviewer: `codex review --base origin/main`, transcribed by the coordinator.

Codex found no actionable defects in the changes. `bin/keymap-parity` passed. Its sandbox again refused writes to the QMK checkout, so it could not run `bin/tap-hold-test`; the coordinator's run on the same commit passed 11 tests.

No findings.

## Round 5 — 2026-10-12T15:09Z — 778d59c

No `REVIEW.md` or `REVIEW.local.md` in the repository; the reviewer's default Bugs, Security and Compliance passes apply. Base: `origin/main`, fetched before this round; `git log origin/main..HEAD` shows 24 commits. No uncommitted changes. This round re-reads the whole diff and the two fix commits since round 3 (`2cd24be`, `d15cc44`).

Current state: `bin/tap-hold-test` 11/11 green; Ruby suite 59 runs, 0 failures; `bin/keymap-parity` exit 0; `shellcheck bin/tap-hold-test` and `rubocop bin lib test` are clean. `clang-format --dry-run --Werror` now fails on `test/tap_hold/config.h` (finding below). `qmk compile` was not re-run: no keymap file changed since round 3.

Bugs: none found. The two round 3 fixes do what they say: the runner copies `tap_hold.h` unconditionally, and `test_common.h` now loads before `keymap_config.h`. The two headers still share no macro, so the test results are the same.

Security: nothing found. The runner's `rm -rf` stays guarded by `${qmk_home:?}` and a fixed folder under QMK's `.build/`.

Compliance: every test named in `plan.md`'s Proof exists and passes. No test was weakened, skipped or deleted. Round 1's Important finding is still open: no box in `keyboard-checklist.md` is ticked, so the on-keyboard half of the first five acceptance criteria still has no evidence.

- [ ] Important: `d15cc44` breaks the lint check. The Google base style sorts includes inside a block, so `clang-format --dry-run --Werror test/tap_hold/config.h` fails with "code should be clang-formatted" and wants `keymap_config.h` first again. Plan step 6 and §7a need clang-format clean. A blank line between the includes does not help; a comment line between them does (checked in a scratch copy), for example `// The keymap's settings override QMK's test defaults.` — this keeps the plan's order and passes clang-format. — `test/tap_hold/config.h:3` →
- [ ] Nit: `test_keymap.c` includes `tap_hold.h` after the `chordal_hold_layout` definition, in the middle of the file. Move it up next to `quantum.h`. — `test/tap_hold/test_keymap.c:8` →

## Round 6 (Codex) — 2026-10-12 — 778d59c

Reviewer: `codex review --base origin/main`, transcribed by the coordinator.

Codex found no actionable defects in the changes. Its sandbox again refused writes to the QMK checkout, so it could not run `bin/tap-hold-test`; the coordinator's run on the same commit passed 11 tests.

No findings.
