# Intent: Move the Model 100 to QMK firmware

Author: Etienne van Delden de la Haije. Status: accepted. Type: refactor.

Issue: [#8](https://github.com/eirvandelden/keyboardio-config/issues/8). Background and research: `docs/qmk-migration.md`.

## Problem

The firmware and tools my keyboard depends on are abandoned. Kaleidoscope, Chrysalis and Keyboardio's support are no longer maintained, so no fixes or help will come when something breaks.

The behaviour I rely on most, the dual-use modifiers ignoring keys on the same hand, only exists in my own Kaleidoscope fork and in an unmerged pull request (keyboardio/Kaleidoscope#1539). I have to keep carrying that fork myself.

My top-row modifiers still trigger by accident while I type.

My keyboard configuration is not on a firmware with a community behind it.

## Proposed outcome

The keyboard runs QMK, a firmware with an active community, and types exactly as it does today. The keymap, layers and dual-use modifier timing all behave as they do today. The lights keep QMK's defaults for now.

The keymap lives in this repository, and I build the firmware from it on my own machine.

A way back to Kaleidoscope exists and has been tried once.

Improvements that QMK makes possible, such as Flow Tap tuning, Caps Word and Autocorrect, come in later changes. Bringing back today's lights (the rainbow trail on key press, per-layer colours, and lights turning off when idle or when the Mac sleeps) is [#11](https://github.com/eirvandelden/keyboardio-config/issues/11), a later change. Building the firmware in GitHub Actions is [#10](https://github.com/eirvandelden/keyboardio-config/issues/10), a later change. Removing the Kaleidoscope sketch, the Chrysalis layout and the fork from this repository comes in a follow-up branch and pull request. Researching what to reuse from Miryoku is [#9](https://github.com/eirvandelden/keyboardio-config/issues/9), after this change.

## Affected users and systems

- Me, typing on the Model 100 every workday, on a Mac set to Dvorak in software.
- The Model 100 itself, including its bootloader, which must stay untouched.
- This repository: the new QMK keymap. The Kaleidoscope sketch and Chrysalis layout stay for now.
- My Kaleidoscope fork at `~/Developer/Kaleidoscope`, still needed for the way back.
- The QMK Model 100 port (qmk/qmk_firmware#26397), which is not merged yet.

## Constraints

- The first switch keeps today's feel. Every key on every layer matches the current Chrysalis layout.
- Chordal Hold is on. It is QMK's version of my opposite-hands rule, so it counts as part of today's feel even though it is not an exact copy.
- The Mission Control key uses QMK's `KC_MCTL`, which sends `0x29F` instead of the `0x2A2` Chrysalis sends.
- Caps Word and Autocorrect stay off. Both read QWERTY key codes as letters, which software Dvorak breaks.
- The QMK port only exists on `shieldsd/qmk_firmware@keyboardio-model100-pr` until it merges. The build must work against that branch now and move to upstream QMK later.
- I install the QMK tools on my machine myself.

## Success

- Every key on every layer has been checked once against the current Chrysalis layout.
- I have typed on QMK for a week of normal work without a reason to go back.
- Going back to Kaleidoscope has been tried once and works.
- The firmware builds on my machine from this repository.

## Open questions

None.
