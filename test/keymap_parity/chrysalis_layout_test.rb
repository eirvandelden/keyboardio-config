require "test_helper"

class ChrysalisLayoutTest < Minitest::Test
  include ChrysalisFixtures

  def test_plain_key_is_its_hid_usage
    assert_equal [ :key, 51, [] ], chrysalis_layout([ 0, 17 ] => 51).key(0, 1, 1)
  end

  def test_zero_is_no_key
    assert_equal [ :none ], chrysalis_layout([ 0, 0 ] => 0).key(0, 0, 0)
  end

  def test_transparent_code_is_transparent
    assert_equal [ :transparent ], chrysalis_layout.key(0, 0, 0)
  end

  def test_modifier_flags_on_a_chrysalis_key_are_translated_to_the_same_modifiers_as_qmk
    layout = chrysalis_layout([ 0, 0 ] => 0x133, [ 0, 1 ] => 0x81e, [ 0, 2 ] => 0x251, [ 0, 3 ] => 0x1533)

    assert_equal [ :key, 51, [ :lctl ] ], layout.key(0, 0, 0)
    assert_equal [ :key, 30, [ :lsft ] ], layout.key(0, 0, 1)
    assert_equal [ :key, 0x51, [ :lalt ] ], layout.key(0, 0, 2)
    assert_equal [ :key, 0x33, [ :lctl, :lgui, :ralt ] ], layout.key(0, 0, 3)
  end

  def test_dual_use_code_gives_tap_key_from_low_byte_and_modifier_from_high_byte
    layout = chrysalis_layout([ 0, 0 ] => 49_189, [ 0, 1 ] => 49_446, [ 0, 2 ] => 50_973)

    assert_equal [ :mod_tap, 20, :lctl ], layout.key(0, 0, 0)
    assert_equal [ :mod_tap, 21, :lsft ], layout.key(0, 0, 1)
    assert_equal [ :mod_tap, 12, :rgui ], layout.key(0, 0, 2)
  end

  def test_consumer_usage_is_the_low_ten_bits
    assert_equal [ :consumer, 0xe9 ], chrysalis_layout([ 0, 0 ] => 18_665).key(0, 0, 0)
  end

  def test_mission_control_is_decoded_from_its_code_not_its_category
    assert_equal [ :consumer, 0x2a2 ], chrysalis_layout([ 0, 0 ] => 19_106).key(0, 0, 0)
  end

  def test_led_codes_are_next_previous_and_toggle
    layout = chrysalis_layout([ 0, 0 ] => 17_152, [ 0, 1 ] => 17_153, [ 0, 2 ] => 17_154)

    assert_equal [ :led, :next ], layout.key(0, 0, 0)
    assert_equal [ :led, :previous ], layout.key(0, 0, 1)
    assert_equal [ :led, :toggle ], layout.key(0, 0, 2)
  end

  def test_lock_and_shift_layer_keys_carry_their_target
    layout = chrysalis_layout([ 0, 0 ] => 17_409, [ 0, 1 ] => 17_451)

    assert_equal [ :layer, :toggle, 1 ], layout.key(0, 0, 0)
    assert_equal [ :layer, :momentary, 1 ], layout.key(0, 0, 1)
  end

  def test_layer_key_target_four_is_renumbered_to_three
    assert_equal [ :layer, :momentary, 3 ], chrysalis_layout([ 0, 0 ] => 17_454).key(0, 0, 0)
  end

  def test_layer_key_that_targets_an_empty_chrysalis_layer_is_refused
    error = assert_raises(KeymapParity::Error) { chrysalis_layout([ 0, 0 ] => 17_453).key(0, 0, 0) }

    assert_includes error.message, "layer 3"
  end

  def test_unknown_chrysalis_code_stops_with_that_code
    error = assert_raises(KeymapParity::Error) { chrysalis_layout([ 0, 0 ] => 12_345).key(0, 0, 0) }

    assert_includes error.message, "12345"
  end

  def test_key_is_addressed_by_row_and_column
    assert_equal [ :key, 4, [] ], chrysalis_layout([ 2, 3 * 16 + 15 ] => 4).key(2, 3, 15)
  end
end
