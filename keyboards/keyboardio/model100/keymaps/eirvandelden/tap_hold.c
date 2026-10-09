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
