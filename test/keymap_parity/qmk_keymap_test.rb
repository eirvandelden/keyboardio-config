require "test_helper"

class QmkKeymapTest < Minitest::Test
  include QmkFixtures

  def test_left_half_matrix_position_maps_to_kaleidoscope_column_seven_minus_column
    keymap = qmk_keymap({ [ 0, 0 ] => "DV_A", [ 0, 5 ] => "DV_B" })

    assert_equal [ :key, 4, [] ], keymap.key(0, 0, 0)
    assert_equal [ :key, 17, [] ], keymap.key(0, 0, 5)
  end

  def test_right_half_matrix_position_maps_to_kaleidoscope_column_fifteen_minus_column
    keymap = qmk_keymap({ [ 0, 6 ] => "DV_A", [ 0, 11 ] => "DV_B" })

    assert_equal [ :key, 4, [] ], keymap.key(0, 0, 10)
    assert_equal [ :key, 17, [] ], keymap.key(0, 0, 15)
  end

  def test_inner_column_key_maps_to_row_zero_column_six
    assert_equal [ :key, 4, [] ], qmk_keymap({ [ 0, 18 ] => "DV_A" }).key(0, 0, 6)
  end

  def test_names_are_decoded_into_the_same_descriptions_as_chrysalis
    keymap = qmk_keymap({
      [ 0, 0 ] => "DV_LCBR", [ 0, 1 ] => "LCTL(DV_S)", [ 0, 2 ] => "LCTL_T(DV_QUOT)",
      [ 0, 3 ] => "MO(NUMBERS)", [ 0, 4 ] => "TG(MEDIA)", [ 0, 5 ] => "KC_VOLU",
      [ 0, 12 ] => "RM_TOGG", [ 0, 13 ] => "KC_NO", [ 0, 14 ] => "KC_MCTL", [ 0, 15 ] => "RGUI_T(DV_C)"
    })

    assert_equal [ :key, 45, [ :lsft ] ], keymap.key(0, 0, 0)
    assert_equal [ :key, 51, [ :lctl ] ], keymap.key(0, 0, 1)
    assert_equal [ :mod_tap, 20, :lctl ], keymap.key(0, 0, 2)
    assert_equal [ :layer, :momentary, 1 ], keymap.key(0, 0, 3)
    assert_equal [ :layer, :toggle, 3 ], keymap.key(0, 0, 4)
    assert_equal [ :consumer, 0xe9 ], keymap.key(0, 0, 5)
    assert_equal [ :led, :toggle ], keymap.key(0, 1, 0)
    assert_equal [ :none ], keymap.key(0, 1, 1)
    assert_equal [ :consumer, 0x29f ], keymap.key(0, 1, 2)
    assert_equal [ :mod_tap, 12, :rgui ], keymap.key(0, 1, 3)
  end

  def test_unknown_qmk_name_stops_with_that_name
    error = assert_raises(KeymapParity::Error) { qmk_keymap({ [ 0, 0 ] => "DV_NOPE" }) }

    assert_includes error.message, "DV_NOPE"
  end

  def test_qmk_keymap_without_exactly_four_layers_is_refused
    assert_raises(KeymapParity::Error) { qmk_keymap(layers: 3) }
    assert_raises(KeymapParity::Error) { qmk_keymap(layers: 5) }
  end

  def test_qmk_layer_without_sixty_four_keys_is_refused
    assert_raises(KeymapParity::Error) { qmk_keymap(positions: layout_positions.first(63)) }
  end

  def test_layout_positions_that_miss_or_repeat_a_kaleidoscope_position_are_refused
    positions = layout_positions
    positions[1] = positions[0]

    assert_raises(KeymapParity::Error) { qmk_keymap(positions: positions) }
  end

  def test_layer_names_are_resolved_from_the_enum_and_must_follow_its_order
    reordered = keymap_source.sub("BASE, NUMBERS, NAVIGATION, MEDIA", "BASE, NAVIGATION, NUMBERS, MEDIA")

    assert_equal [ :layer, :momentary, 1 ], qmk_keymap({ [ 0, 0 ] => "MO(NUMBERS)" }).key(0, 0, 0)
    error = assert_raises(KeymapParity::Error) { qmk_keymap({}, source: reordered) }
    assert_includes error.message, "order"
  end

  def test_failing_qmk_command_stops_with_its_output
    error = assert_raises(KeymapParity::Error) do
      KeymapParity::QmkKeymap::Command.new.call("sh", "-c", "echo broken >&2; exit 3")
    end

    assert_includes error.message, "broken"
  end
end
