#pragma once

#include "quantum.h"

// Call for every key event, in press order, from pre_process_record_user().
void tap_hold_track_event(uint16_t keycode, keyrecord_t* record);
