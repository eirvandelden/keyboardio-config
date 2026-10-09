# Intent: Stray Ctrl+Cmd chords when typing "claude"

Author: Etienne van Delden de la Haije. Status: accepted. Type: bugfix. Delivery: autonomous.

## Problem

Etienne opens a new herdr pane with the Ctrl+S prefix and `-`, then types `claude` at once. The pane shows `7;13u17;13ude` instead of `claude`. The `c` and the `l` vanish, and the `a` and the `u` arrive as Ctrl+Cmd chords (`\e[97;13u`, `\e[117;13u`; modifier 13 is Ctrl+Super). zsh inside herdr 0.9.3 cannot decode those reports and types their tails as text.

The keyboard runs the QMK keymap from pull request #12 (`keyboards/keyboardio/model100/keymaps/eirvandelden/keymap.c`). There, `c` is `RGUI_T(DV_C)` and `l` is `RCTL_T(DV_L)`: right-hand top-row dual-use keys that act as Command and Control when held. During the roll, both become held modifiers.

Evidence: five tries with the Model100 reproduce it five times. Five tries with the MacBook's built-in keyboard reproduce it zero times. It never shows in a plain Ghostty tab, where the chords are dropped without visible text. A single `cat -v` try, after Enter and a one-second pause, gave a clean `claude`.

Etienne also assumed that the right-hand dual-use keys send Left Shift, Left Command and Left Control. They send the right-side variants.

## Proposed outcome

Typing `claude`, or any word with the same right-hand roll, at normal speed gives exactly the typed letters on the Model100, also straight after opening a pane. Deliberate opposite-hand chords on the top-row dual-use keys keep working. Every dual-use Shift, Command and Control key sends the left-side variant, on both halves of the keyboard.

Once a herdr stable release contains herdrdev/herdr#5017, a stray Super chord no longer types text into a plain shell pane.

## Affected users and systems

- Etienne, typing on the Keyboardio Model100 with macOS set to Dvorak.
- The QMK keymap in this repository: `keyboards/keyboardio/model100/keymaps/eirvandelden/` (`keymap.c`, `config.h`).
- herdr, installed with Homebrew, currently 0.9.3.

## Constraints

- This branch stacks on `8-move-the-model-100-to-qmk-firmware` (pull request #12). Its pull request targets that branch and rebases when that branch moves.
- That base branch has 20 local commits that are not on `origin`. Pushing it is not part of this change. If those commits are still unpushed when this pull request opens, stop and ask.
- Only this repository's QMK keymap changes. If the keymap alone cannot fix the fault, stop and ask.
- `bin/keymap-parity` compares the QMK keymap with the Chrysalis layout, which stays unchanged. The switch to left-side modifiers is a deliberate difference from that layout.
- macOS applies Dvorak in software; the keymap sends QWERTY key positions through the `DV_` keycodes.
- Approved permissions: agents may build and flash the Model100 with the QMK tooling. Agents may run `brew upgrade herdr` (playbook rule 8), but only to a stable release that contains herdrdev/herdr#5017; never the preview channel.
- Personal repository; autonomous delivery (playbook §7a).

## In scope

- The Model100 stops sending Ctrl+Cmd chords when `claude` is typed at once, also straight after opening a pane.
- Every right-side dual-use modifier sends its left-side variant: on the base layer `g` (Shift), `c` (Command) and `l` (Control); on the numbers layer `7`, `8` and `0`; on the navigation layer `=` (Command).
- Upgrading herdr to the first stable release that contains herdrdev/herdr#5017, when one exists before this change finishes.

## Out of scope

- The Model01.
- The Kaleidoscope sketch, the Chrysalis layout, the eirvandelden/Kaleidoscope fork and the eirvandelden/qmk_firmware fork.
- The herdr preview channel or a build from master.
- Etienne's dotfiles: they play no part in the fault.

## Acceptance criteria

- Opening a new herdr pane with Ctrl+S, `-` and typing `claude` at once gives `claude`, five tries out of five.
- In `cat -v`, after Enter and a one-second pause, typing `claude` fast shows `claude`, five tries out of five.
- Holding `c` and pressing `a` with the left hand selects all (Cmd+A).
- Holding `l` and pressing `a` with the left hand moves the zsh cursor to the start of the line (Ctrl+A).
- A key-event viewer reports Left Shift, Left Command and Left Control while `g`, `c` and `l` are held. The same holds for `7`, `8` and `0` on the numbers layer and `=` on the navigation layer.
- Once herdr is upgraded, pressing Ctrl+Cmd+A in a plain zsh pane types no text. If no such stable release exists when the change finishes, herdr stays at 0.9.3 and the delivery account says so.

## Flagged concerns

- Stopping accidental chords can make deliberate opposite-hand chords less reliable. Chosen side: stop the accidental chords. An occasional missed deliberate chord means pressing it again.

## Open questions

None.
