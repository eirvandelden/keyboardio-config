# Keyboard checklist: Move the Model 100 to QMK firmware

Checks on the keyboard for acceptance criteria 4–12 of `spec.md`. Tick each box after trying it.

Before the first QMK flash: the way-back `.bin` (built from commit `1ee038c`) is kept outside the repository, and `git diff --exit-code main -- Model01 Model100 Chrysalis_Keyboardio-Model-100_layout.json` is clean.

Flash with `qmk flash -kb keyboardio/model100 -km eirvandelden`. Hold `Prog` while plugging in to reach the bootloader. Type the checks below with the Mac in Dvorak.

## Every key, every layer

Criterion 4. One pass over every key, once. `bin/keymap-parity` has already compared the keymap with Chrysalis. This pass catches a wrong entry in the script's own name table. Layer keys are checked under "Palm keys reach the layers".

### Base layer

- [ ] Top row, left to right: Prog key sends nothing, then `1 2 3 4 5` on the left half and `6 7 8 9 0` on the right half.
- [ ] Top-right key locks and unlocks the numbers layer.
- [ ] Left outer column, top to bottom: `{`, `(`, `[`.
- [ ] Left top letter row: `'` `,` `.` `p` `y`. Each of the first four also works as a modifier (see "Dual-use key taps and holds").
- [ ] Left home row: `a o e u i`.
- [ ] Left bottom row: `;` `q` `j` `k` `x`.
- [ ] Left inner column, top to bottom: LED next, Spotlight (Cmd+Space), Ctrl+S.
- [ ] Right inner column, top to bottom: previous track, play/pause, next track.
- [ ] Right top letter row: `f g c r l`, then `=` at the outer edge. `g c r l` also work as modifiers.
- [ ] Right home row: `d h t n s`, then `-` at the outer edge.
- [ ] Right bottom row: `b m w v z`, then `\` at the outer edge.
- [ ] Left thumb keys, in the order of the thumb row in `keymap.c` (every other key of that row): Esc, Enter, Tab, left Shift.
- [ ] Right thumb keys, in the same order: Backspace, Space, Delete, right Shift.

### Numbers layer

- [ ] Second row, left: `}`, then `1 2 3 4 5`. Right: `6 7 8 9 0`. `1 2 3 4` and `7 8 9 0` also work as modifiers (Ctrl, Alt, Cmd, Shift and Shift, Cmd, Alt, Ctrl).
- [ ] Home row left: `! @ # $ %`. Home row right: `^ & * ( )`.
- [ ] Outer column: `}`, `)`, `]`.
- [ ] Left thumb Tab position sends Backspace.
- [ ] Opposite palm key reaches the media layer.

### Navigation layer

- [ ] Left home row: Ctrl, Alt, Cmd, Shift (plain modifiers).
- [ ] Right home row: Caps Lock, left, down, up, right arrow, then `_` at the outer edge.
- [ ] Right bottom row: Insert, Home, Page down, Page up, End, then `|` at the outer edge.
- [ ] Left second row: `` ` `` with Ctrl on hold. Right second row: `=` with Cmd on hold, `/` with Alt on hold.
- [ ] Outer column: `]`, `)`, `}`.
- [ ] Opposite palm key reaches the media layer.

### Media layer

- [ ] Home row left: Ctrl, Alt, Cmd, Shift. Home row right: previous, volume down, volume up, next.
- [ ] Second row right: LED previous, LED toggle (twice), LED next.
- [x] Third row right: brightness down, brightness up.
- [ ] Thumb row: mute on the second key of the thumb row in `keymap.c` (the first right thumb key).

## Palm keys reach the layers

Criterion 5.

- [ ] Hold the right palm key and press the right arrow position: the cursor moves right.
- [x] Hold both palm keys and press volume up: the volume goes up.
- [ ] Hold the left palm key and press the home-row key left of centre that types `!` on the numbers layer: `!` types.

## Dual-use key taps and holds

Criterion 6.

- [x] Tap the top-row key in the `p` position: types `p`.
- [x] Hold it and tap `h` on the other hand: types `H`.
- [ ] The numbers and navigation mod-taps tap their digit or symbol and hold their modifier.
- [ ] Hold two modifiers together (for example `Ctrl` and `Alt`), then press a key. Flow Tap's default filter leaves digits, grave and brackets without protection, so watch for stray taps.

## Same hand types letters

Criterion 7. Do this within 200 ms: after `TAPPING_TERM`, Chordal Hold no longer stops a hold.

- [x] Press the `p`/Shift key and `u` on the same hand, quickly: types `pu`, not `U`.

## Typing people

Criterion 8.

- [x] Type `people` at normal speed ten times. No modifier fires from the top-row keys. Typed again on 2026-10-02 after the Shift keys left Flow Tap: still no modifier.
- [x] Type `word?` at normal speed ten times: each gives `word?`, not `ppp/`.
- [x] Type `graph good` at speed ten times. Each Shift key (`g` on the right, `p` on the left) rolls into the other hand without capitals: no `GRAPH`, `grapH` or `gOod`.

## Light keys

Criterion 9.

- [x] LED next changes the light effect.
- [ ] After flashing, the lights start off. LED next goes to the key-press fade first, then solid colour, breathing, rainbow wave and off, and nothing else.
- [x] In the key-press fade, a pressed key fades out over about 5 seconds, and every key of a fast typed sentence stays lit through its fade.
- [ ] In the key-press fade, type slowly, a key every few seconds, for over a minute: every key keeps fading out over its own 5 seconds, and nothing goes dark all at once.
- [ ] Unplug and plug back in: the lights start off again.
- [ ] Press LED next first (the keyboard starts in the off effect), then LED toggle turns the lights off and on.

## No Caps Word or Autocorrect

Criterion 12. Checked by the agent on 2026-10-01 with the build tools, recorded here.

- [x] `grep -rnE 'CAPS_WORD|AUTOCORRECT|CW_TOGG|QK_CAPS_WORD|AC_TOGG|AC_ON|QK_AUTOCORRECT' keyboards/ qmk.json` exits 1 (no match).
- [x] `qmk info -kb keyboardio/model100 -km eirvandelden -f json` shows neither `caps_word` nor `autocorrect`.

## Way back tried

Criterion 10.

- [ ] Hold `Prog`, plug in, and flash the kept Kaleidoscope `.bin` with `dfu-util -d 3496:0005 -a 0 -R -D <file>.bin`.
- [ ] Import `Chrysalis_Keyboardio-Model-100_layout.json` in Chrysalis. The keyboard behaves as before.
- [ ] Flash QMK again.

## A week of work

Criterion 11.

- [ ] A week of normal work on QMK without a reason to go back. Date started: ______

## Findings

Doubled letters, accidental modifiers or any other regression go here, one line each, with the date. For each one, decide whether it blocks the change. A fix that needs new work gets a new plan step first.

- 2026-10-02, better: doubled key presses, especially with modifiers, which happened on Kaleidoscope, have not appeared on QMK on the first day. Keep watching through the week. Not blocking.
- 2026-10-02, fixed: the left inner middle key opened Mission Control instead of Spotlight. It now sends Cmd+Space. Not blocking.
- 2026-10-02, fixed: `word?` typed at speed gave `ppp/` because Flow Tap settled the Shift key as a tap. The Shift keys are now out of Flow Tap. Not blocking.
- 2026-10-02, fixed: the port's 29 light effects were too many, and the key-press fade disappeared too quickly. The LED key now cycles off, a 5-second key-press fade, solid colour, breathing and rainbow wave. Not blocking.
