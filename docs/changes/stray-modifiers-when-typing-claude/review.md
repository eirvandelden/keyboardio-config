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
- [ ] Nit: the build note says the left-side switch newly gives `g` and `7` the `word?` Shift exception because `is_shift_mod_tap()` matched only `MOD_LSFT`. That is wrong: `QK_MOD_TAP_GET_MODS(RSFT_T(...))` is `0x12`, and `0x12 & MOD_LSFT` is non-zero, so the right-side Shift keys already had the exception (as `docs/qmk-migration.md` said before this branch). Correct or remove the note so the delivery account does not claim a behaviour change that did not happen. — `docs/changes/stray-modifiers-when-typing-claude/plan.md:142` →
- [ ] Nit: `test_real_keymap_dual_use_keys_send_left_side_modifiers` checks that each mod-tap appears somewhere on its layer (`assert_includes`), not at its position, as design decision 6 describes. A keymap that put `LGUI_T(DV_C)` on the wrong key would still pass this test; only `bin/keymap-parity` would catch it. — `test/keymap_parity/qmk_keymap_test.rb:66` →
- [ ] Nit: `is_rolled()` and `set_rolled()` index `rolled[key.row]` with no bounds check. `tap_hold_track_event()` sees every event, and QMK's virtual key locations (encoders 252/253, DIP switches 250/251) would read and write far past the array if one of those features is ever enabled. The Model100 keymap enables none today. — `keyboards/keyboardio/model100/keymaps/eirvandelden/tap_hold.c:42` →
- [ ] Nit: `tap_hold_track_event()` reads the keycode again with `get_record_keycode(record, false)`, which depends on the layer cache that `pre_process_record_quantum()` has just updated. `pre_process_record_user()` already receives that `keycode`; passing it in removes the hidden ordering dependency. — `keyboards/keyboardio/model100/keymaps/eirvandelden/tap_hold.c:64` →
- [ ] Nit: the test fixture uses `std::find` and `std::begin`/`std::end` without `<algorithm>` and `<iterator>`; it compiles only through transitive includes of the QMK test headers. — `test/tap_hold/test_tap_hold.cpp:43` →

## Round 2 (Codex) — 2026-10-09 — d90b69a

Reviewer: `codex review --base origin/main`, transcribed by the coordinator.

Codex found no actionable defects in the changes. It ran `bin/keymap-parity`, which completed. It could not run `bin/tap-hold-test`: its sandbox refused to write into the QMK checkout's `.build/` folder outside the worktree. The coordinator ran `bin/tap-hold-test` outside the sandbox on the same commit: 10 tests passed.

No findings.
