// The real tap-hold code (tap_hold.c) and settings (keymap_config.h) are
// under test. Keycodes and key positions come from the tests themselves.
#include "quantum.h"

// QMK links this table into every Chordal Hold build; tap_hold.c's
// chordal_hold_handedness() is what decides, so its contents are unused.
const char chordal_hold_layout[MATRIX_ROWS][MATRIX_COLS] PROGMEM = {{0}};
#include "tap_hold.h"

bool pre_process_record_user(uint16_t keycode, keyrecord_t* record) {
  tap_hold_track_event(record);
  return true;
}
