# Keyboard checklist: Stray Ctrl+Cmd chords when typing "claude"

Checks on the keyboard for the acceptance criteria in `intent.md`. Tick each box after trying it. The host tests (`bin/tap-hold-test`) already cover the tap-hold logic; these checks cover the flashed keymap and the real matrix.

Flash from the worktree root with `qmk flash -kb keyboardio/model100 -km eirvandelden`. Hold `Prog` while plugging in to reach the bootloader. The Mac stays in Dvorak.

## Typing "claude"

- [ ] In herdr, open a pane with Ctrl+S then `-`, and type `claude` at once. The pane shows `claude`. Five tries, five clean results.
- [ ] In `cat -v`, press Enter, wait one second, and type `claude` fast. It shows `claude`. Five tries, five clean results.

## Deliberate chords

- [ ] In a text field, hold `c` and press `a` with the left hand. The text is selected (Cmd+A).
- [ ] In zsh, hold `l` and press `a` with the left hand. The cursor moves to the start of the line (Ctrl+A).

## Left-side modifiers

Use a key-event viewer of your choice. None is installed, and macOS has none built in. Each held key reports the left-side modifier.

- [ ] Base layer: `g` reports Left Shift, `c` Left Command, `l` Left Control.
- [ ] Numbers layer: `7` reports Left Shift, `8` Left Command, `0` Left Control.
- [ ] Navigation layer: `=` reports Left Command.

## herdr

- [ ] Only if herdr was upgraded to a stable release that contains herdrdev/herdr#5017: Ctrl+Cmd+A in a plain zsh pane types no text. If herdr stays at 0.9.3, leave this unticked and say so in the delivery account.
