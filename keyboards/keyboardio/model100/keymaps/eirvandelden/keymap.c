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
    DV_LPRN        , DV_A           , DV_O           , DV_E           , DV_U           , DV_I           , KC_MCTL        , KC_MPLY        , DV_D           , DV_H           , DV_T           , DV_N           , DV_S           , DV_MINS        ,
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
