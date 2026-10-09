#include "quantum.h"

// Rows 0-3 of the matrix are the left half, rows 4-7 the right half.
char chordal_hold_handedness(keypos_t key) {
  return key.row < MATRIX_ROWS / 2 ? 'L' : 'R';
}

// Shift right after a letter is ordinary typing (`word?`), so the Shift keys
// decide by hold time; Flow Tap keeps guarding Ctrl, Alt and Cmd.
static bool is_shift_mod_tap(uint16_t keycode) {
  return IS_QK_MOD_TAP(keycode) && (QK_MOD_TAP_GET_MODS(keycode) & MOD_LSFT);
}

uint16_t get_flow_tap_term(uint16_t keycode, keyrecord_t* record, uint16_t prev_keycode) {
  if (is_shift_mod_tap(keycode)) {
    return 0;
  }
  if (is_flow_tap_key(keycode) && is_flow_tap_key(prev_keycode)) {
    return FLOW_TAP_TERM;
  }
  return 0;
}

// Matrix positions of mod-taps that were pressed while another mod-tap on the
// same hand was still held: a roll such as `c` then `l` in "claude". Both keys
// give up Permissive Hold until their next press, so a key nested inside the
// roll cannot turn both into held modifiers.
static matrix_row_t rolled[MATRIX_ROWS];

static struct {
  keypos_t key;
  bool is_mod_tap;
  bool is_down;
} last_press;

static bool is_rolled(keypos_t key) {
  return rolled[key.row] & ((matrix_row_t)1 << key.col);
}

static void set_rolled(keypos_t key, bool value) {
  matrix_row_t bit = (matrix_row_t)1 << key.col;
  rolled[key.row] = value ? (rolled[key.row] | bit) : (rolled[key.row] & ~bit);
}

static bool continues_roll(keypos_t key, bool is_mod_tap) {
  return is_mod_tap && last_press.is_mod_tap && last_press.is_down &&
         chordal_hold_handedness(key) == chordal_hold_handedness(last_press.key);
}

static void track_press(keypos_t key, bool is_mod_tap) {
  bool rolling = continues_roll(key, is_mod_tap);
  set_rolled(key, rolling);
  if (rolling) {
    set_rolled(last_press.key, true);
  }
  last_press.key = key;
  last_press.is_mod_tap = is_mod_tap;
  last_press.is_down = true;
}

void tap_hold_track_event(keyrecord_t* record) {
  keypos_t key = record->event.key;
  if (record->event.pressed) {
    track_press(key, IS_QK_MOD_TAP(get_record_keycode(record, false)));
  } else if (KEYEQ(key, last_press.key)) {
    last_press.is_down = false;
  }
}

bool get_permissive_hold(uint16_t keycode, keyrecord_t* record) {
  return !is_rolled(record->event.key);
}
