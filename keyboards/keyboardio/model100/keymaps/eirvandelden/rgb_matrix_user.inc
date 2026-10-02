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

// Milliseconds since the key at this LED was last pressed, at most KEY_FADE_MS.
static uint16_t key_fade_elapsed(uint8_t led) {
  for (int8_t j = g_last_hit_tracker.count - 1; j >= 0; j--) {
    if (g_last_hit_tracker.index[j] == led) {
      uint16_t tick = g_last_hit_tracker.tick[j];
      return tick < KEY_FADE_MS ? tick : KEY_FADE_MS;
    }
  }
  return KEY_FADE_MS;
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
