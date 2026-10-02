RGB_MATRIX_EFFECT(lights_off)
RGB_MATRIX_EFFECT(key_fade)

#ifdef RGB_MATRIX_CUSTOM_EFFECT_IMPLS

static bool lights_off(effect_params_t* params) {
  RGB_MATRIX_USE_LIMITS(led_min, led_max);
  for (uint8_t i = led_min; i < led_max; i++) {
    rgb_matrix_set_color(i, 0, 0, 0);
  }
  return rgb_matrix_check_finished_leds(led_max);
}

#define KEY_FADE_MS 5000

uint32_t key_fade_pressed_at(uint8_t led);

// Milliseconds since the key at this LED was last pressed, at most KEY_FADE_MS.
static uint16_t key_fade_elapsed(uint8_t led) {
  uint32_t pressed_at = key_fade_pressed_at(led);
  if (pressed_at == 0) {
    return KEY_FADE_MS;
  }
  uint32_t elapsed = timer_elapsed32(pressed_at);
  return elapsed < KEY_FADE_MS ? elapsed : KEY_FADE_MS;
}

static bool key_fade(effect_params_t* params) {
  RGB_MATRIX_USE_LIMITS(led_min, led_max);
  for (uint8_t i = led_min; i < led_max; i++) {
    RGB_MATRIX_TEST_LED_FLAGS();
    hsv_t hsv = rgb_matrix_config.hsv;
    hsv.v = scale8(hsv.v, 255 - (uint32_t)key_fade_elapsed(i) * 255 / KEY_FADE_MS);
    rgb_t rgb = rgb_matrix_hsv_to_rgb(hsv);
    rgb_matrix_set_color(i, rgb.r, rgb.g, rgb.b);
  }
  return rgb_matrix_check_finished_leds(led_max);
}

#endif
