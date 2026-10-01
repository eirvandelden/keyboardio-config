require "test_helper"

class ComparisonTest < Minitest::Test
  include ChrysalisFixtures
  include QmkFixtures

  # Chrysalis r1c(n) sits at LAYOUT index 12 + n for n in 0..5.
  def differences(chrysalis_code, qmk_name, chrysalis_layer: 0, qmk_layer: 0, column: 1, chrysalis_overrides: {})
    chrysalis = chrysalis_layout({ [ chrysalis_layer, 16 + column ] => chrysalis_code }.merge(chrysalis_overrides))
    qmk = qmk_keymap({ [ qmk_layer, 12 + column ] => qmk_name })
    KeymapParity::Comparison.new(chrysalis, qmk).differences
  end

  def test_untouched_keymaps_have_no_differences
    assert_empty KeymapParity::Comparison.new(chrysalis_layout, qmk_keymap).differences
  end

  def test_plain_chrysalis_key_matches_its_dvorak_name
    assert_empty differences(51, "DV_S")
  end

  def test_chrysalis_key_with_shift_matches_shifted_dvorak_name
    assert_empty differences(2093, "DV_LCBR")
  end

  def test_chrysalis_key_with_control_matches_lctl_wrapper
    assert_empty differences(307, "LCTL(DV_S)")
  end

  def test_dual_use_key_matches_mod_tap_with_same_tap_key_and_modifier
    assert_empty differences(49_189, "LCTL_T(DV_QUOT)")
  end

  def test_dual_use_key_with_wrong_modifier_is_reported
    assert_equal 1, differences(49_189, "LALT_T(DV_QUOT)").size
  end

  def test_shift_to_layer_matches_mo_and_lock_to_layer_matches_tg
    assert_empty differences(17_451, "MO(NUMBERS)")
    assert_empty differences(17_409, "TG(NUMBERS)")
  end

  def test_chrysalis_layer_four_is_compared_with_qmk_media_layer
    assert_empty differences(18_665, "KC_VOLU", chrysalis_layer: 4, qmk_layer: 3)
    refute_empty differences(18_665, "KC_VOLU", chrysalis_layer: 4, qmk_layer: 2)
  end

  def test_consumer_keys_match_media_and_brightness_names
    { 18_543 => "KC_BRIU", 18_544 => "KC_BRID", 18_613 => "KC_MNXT", 18_614 => "KC_MPRV",
      18_637 => "KC_MPLY", 18_658 => "KC_MUTE", 18_666 => "KC_VOLD" }.each do |code, name|
      assert_empty differences(code, name), name
    end
  end

  def test_led_keys_match_rm_next_rm_prev_rm_togg
    { 17_152 => "RM_NEXT", 17_153 => "RM_PREV", 17_154 => "RM_TOGG" }.each do |code, name|
      assert_empty differences(code, name), name
    end
  end

  def test_transparent_on_upper_layer_matches_transparent
    assert_empty differences(65_535, "KC_TRNS", chrysalis_layer: 1, qmk_layer: 1)
  end

  def test_transparent_on_base_layer_matches_no_key
    assert_empty differences(65_535, "KC_NO")
  end

  def test_a_base_layer_key_that_is_not_transparent_against_no_key_is_reported
    assert_equal 1, differences(51, "KC_NO").size
    assert_equal 1, differences(65_535, "KC_NO", chrysalis_layer: 1, qmk_layer: 1).size
  end

  def test_mission_control_position_is_allowed_to_differ
    chrysalis = chrysalis_layout([ 0, 22 ] => 19_106)
    qmk = qmk_keymap({ [ 0, 32 ] => "KC_MCTL" })

    assert_empty KeymapParity::Comparison.new(chrysalis, qmk).differences
  end

  def test_a_different_key_at_the_mission_control_position_is_reported
    chrysalis = chrysalis_layout([ 0, 22 ] => 19_106)
    qmk = qmk_keymap({ [ 0, 32 ] => "DV_A" })

    assert_equal 1, KeymapParity::Comparison.new(chrysalis, qmk).differences.size
  end

  def test_mission_control_against_mctl_elsewhere_is_reported
    assert_equal 1, differences(19_106, "KC_MCTL").size
  end

  def test_unused_chrysalis_layer_that_is_not_empty_is_reported
    assert_equal 1, differences(65_535, "KC_NO", chrysalis_overrides: { [ 3, 0 ] => 51 }).size
  end

  def test_report_lists_layer_and_kaleidoscope_position_for_each_difference
    chrysalis = chrysalis_layout([ 1, 17 ] => 51, [ 3, 0 ] => 51)
    report = KeymapParity::Comparison.new(chrysalis, qmk_keymap).report

    assert_equal 2, report.size
    assert_match(/layer 1 r1c1/, report.first)
    assert_match(/Chrysalis layer 3 r0c0/, report.last)
  end
end
