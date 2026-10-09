#include QMK_KEYBOARD_H
#include "keymap_dvorak.h"

enum layers { BASE,
              NUMBERS,
              NAVIGATION,
              MEDIA };

const uint16_t PROGMEM keymaps[][MATRIX_ROWS][MATRIX_COLS] = {
    [BASE] = LAYOUT(
    XXXXXXX        , DV_1           , DV_2           , DV_3           , DV_4           , DV_5           , DV_6           , DV_7           , DV_8           , DV_9           , DV_0           , TG(NUMBERS)    ,
    DV_LCBR        , LCTL_T(DV_QUOT), LALT_T(DV_COMM), LGUI_T(DV_DOT) , LSFT_T(DV_P)   , DV_Y           , RM_NEXT        , KC_MPRV        , DV_F           , RSFT_T(DV_G)   , RGUI_T(DV_C)   , LALT_T(DV_R)   , RCTL_T(DV_L)   , DV_EQL         ,
    DV_LPRN        , DV_A           , DV_O           , DV_E           , DV_U           , DV_I           , LGUI(KC_SPC)   , KC_MPLY        , DV_D           , DV_H           , DV_T           , DV_N           , DV_S           , DV_MINS        ,
    DV_LBRC        , DV_SCLN        , DV_Q           , DV_J           , DV_K           , DV_X           , LCTL(DV_S)     , KC_MNXT        , DV_B           , DV_M           , DV_W           , DV_V           , DV_Z           , DV_BSLS        ,
    KC_ESC         , KC_BSPC        , KC_ENT         , KC_SPC         , KC_TAB         , KC_DEL         , KC_LSFT        , KC_RSFT        , MO(NUMBERS)    , MO(NAVIGATION)
  ), [NUMBERS] = LAYOUT(
    _______     , _______     , _______     , _______     , _______     , _______     , _______     , _______     , _______     , _______     , _______     , _______     ,
    DV_RCBR     , LCTL_T(DV_1), LALT_T(DV_2), LGUI_T(DV_3), LSFT_T(DV_4), DV_5        , _______     , _______     , DV_6        , RSFT_T(DV_7), RGUI_T(DV_8), LALT_T(DV_9), RCTL_T(DV_0), _______     ,
    DV_RPRN     , DV_EXLM     , DV_AT       , DV_HASH     , DV_DLR      , DV_PERC     , _______     , _______     , DV_CIRC     , DV_AMPR     , DV_ASTR     , DV_LPRN     , DV_RPRN     , _______     ,
    DV_RBRC     , _______     , _______     , _______     , _______     , _______     , _______     , _______     , _______     , _______     , _______     , _______     , _______     , _______     ,
    _______     , _______     , _______     , _______     , KC_BSPC     , _______     , _______     , _______     , _______     , MO(MEDIA)
  ), [NAVIGATION] = LAYOUT(
    _______        , _______        , _______        , _______        , _______        , _______        , _______        , _______        , _______        , _______        , _______        , _______        ,
    DV_RBRC        , LCTL_T(DV_GRV) , _______        , _______        , _______        , _______        , _______        , _______        , _______        , _______        , RGUI_T(DV_EQL) , LALT_T(DV_SLSH), _______        , _______        ,
    DV_RPRN        , KC_LCTL        , KC_LALT        , KC_LGUI        , KC_LSFT        , _______        , _______        , _______        , KC_CAPS        , KC_LEFT        , KC_DOWN        , KC_UP          , KC_RGHT        , DV_UNDS        ,
    DV_RCBR        , _______        , _______        , _______        , _______        , _______        , _______        , _______        , KC_INS         , KC_HOME        , KC_PGDN        , KC_PGUP        , KC_END         , DV_PIPE        ,
    _______        , _______        , _______        , _______        , _______        , _______        , _______        , _______        , MO(MEDIA)      , _______
  ), [MEDIA] = LAYOUT(
    _______, _______, _______, _______, _______, _______, _______, _______, _______, _______, _______, _______,
    _______, _______, _______, _______, _______, _______, _______, _______, _______, RM_PREV, RM_TOGG, RM_TOGG, RM_NEXT, _______,
    _______, KC_LCTL, KC_LALT, KC_LGUI, KC_LSFT, _______, _______, _______, _______, KC_MPRV, KC_VOLD, KC_VOLU, KC_MNXT, _______,
    _______, _______, _______, _______, _______, _______, _______, _______, _______, _______, KC_BRID, KC_BRIU, _______, _______,
    _______, KC_MUTE, _______, _______, _______, _______, _______, _______, _______, _______
  ) };

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

// The time each LED's key was last pressed, for the key-press fade; 0 is never.
// Kept here because QMK's shared hit list drops presses once its oldest is
// about 65 seconds old.
static uint32_t pressed_at[RGB_MATRIX_LED_COUNT];

// Milliseconds since the key at this LED was last pressed, at most KEY_FADE_MS.
// A finished fade forgets its press, so the 32-bit timer wrapping after about
// 49.7 days cannot light a key that was not pressed.
uint16_t key_fade_elapsed(uint8_t led) {
  if (pressed_at[led] == 0) {
    return KEY_FADE_MS;
  }
  uint32_t elapsed = timer_elapsed32(pressed_at[led]);
  if (elapsed >= KEY_FADE_MS) {
    pressed_at[led] = 0;
    return KEY_FADE_MS;
  }
  return elapsed;
}

static void remember_press(keypos_t key) {
  // Sized as QMK's own caller of rgb_matrix_map_row_column_to_led() sizes it.
  uint8_t leds[LED_HITS_TO_REMEMBER];
  uint8_t count = rgb_matrix_map_row_column_to_led(key.row, key.col, leds);
  for (uint8_t i = 0; i < count; i++) {
    pressed_at[leds[i]] = timer_read32() | 1;
  }
}

bool pre_process_record_user(uint16_t keycode, keyrecord_t* record) {
  if (record->event.pressed) {
    remember_press(record->event.key);
  }
  return true;
}

// Start with the lights off on every power-up, as Kaleidoscope returned to its
// default mode, without overwriting the mode the LED key saved.
void keyboard_post_init_user(void) {
  rgb_matrix_mode_noeeprom(RGB_MATRIX_CUSTOM_lights_off);
}
