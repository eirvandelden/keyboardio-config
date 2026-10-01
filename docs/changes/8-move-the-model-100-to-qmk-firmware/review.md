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

- [ ] Important: Step 1 says to build the way-back firmware from `Model100/Model100.ino` "on `main`". `main` now contains the availability-light merge (#7, `1c57d46`), so following this builds the firmware that was never flashed. Spec requirement 12 says commit `1ee038c`. The plan's doc-update list only says "record where the way-back `.bin` is kept", so this line may survive step 10 — `docs/qmk-migration.md:38` →
- [ ] Important: The userspace setup runs `qmk userspace-add` without first creating `qmk.json`. The plan's own finding says QMK only detects a userspace that already has a valid `qmk.json`, so these instructions fail as written. The plan's doc-update list for step 10 does not include this fix — `docs/qmk-migration.md:88` →
- [ ] Important: Compliance: no spec acceptance criterion has proof yet, and none of the tests named in `plan.md` `## Proof` exist. Expected before implementation, but the branch cannot be pushed for review or merged in this state — `docs/changes/8-move-the-model-100-to-qmk-firmware/plan.md:100` →
- [ ] Nit: Space is on the right thumb (Chrysalis `r1c8` = 44; the draft's last `LAYOUT` row alternates L/R, which puts `KC_SPC` on the right). "left mod plus left-thumb `Enter` or `Space`" should name only `Enter` (or `Tab`/`Esc`) — `docs/qmk-migration.md:212` →
- [ ] Nit: "The inner-column keys ... sit at the end of rows 1–3" disagrees with the draft below it, where they sit in positions 6–7 of each 14-key row, between the halves. Say "at the end of each half's row" or "in the middle of rows 1–3" — `docs/qmk-migration.md:130` →
- [ ] Nit: "They are system tools, and an agent should not install them" contradicts plan step 0, where Etienne gave the implementing agent permission to install the QMK CLI and clone the source. Not in the plan's doc-update list — `docs/qmk-migration.md:46` →
- [ ] Nit: "flash the kept Kaleidoscope `.bin` with the same `dfu-util` command as in step 4". Step 4 runs `qmk flash` and only paraphrases the `dfu-util` call with a `<firmware>.bin` placeholder. Spec requirement 13 asks the doc to describe the way back, so give the literal command with the kept file's path — `docs/qmk-migration.md:42` →
- [ ] Nit: `cspell.yml` points to the machine-local `~/.config/cspell/user-dictionary.txt` with `addWords: true`. Words added from this repository can go to the personal dictionary instead of `project-dictionary.txt`, and a fresh clone without that file gets a missing-dictionary warning — `cspell.yml:7` →
