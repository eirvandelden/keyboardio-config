module KeymapParity
  # Turns a QMK key name, as written in keymap.c, into the same description ChrysalisLayout gives.
  class QmkNames
    PLAIN = {
      "DV_GRV" => 53, "DV_1" => 30, "DV_2" => 31, "DV_3" => 32, "DV_4" => 33, "DV_5" => 34, "DV_6" => 35,
      "DV_7" => 36, "DV_8" => 37, "DV_9" => 38, "DV_0" => 39, "DV_LBRC" => 45, "DV_RBRC" => 46,
      "DV_QUOT" => 20, "DV_COMM" => 26, "DV_DOT" => 8, "DV_P" => 21, "DV_Y" => 23, "DV_F" => 28,
      "DV_G" => 24, "DV_C" => 12, "DV_R" => 18, "DV_L" => 19, "DV_SLSH" => 47, "DV_EQL" => 48,
      "DV_BSLS" => 49, "DV_A" => 4, "DV_O" => 22, "DV_E" => 7, "DV_U" => 9, "DV_I" => 10,
      "DV_D" => 11, "DV_H" => 13, "DV_T" => 14, "DV_N" => 15, "DV_S" => 51, "DV_MINS" => 52,
      "DV_SCLN" => 29, "DV_Q" => 27, "DV_J" => 6, "DV_K" => 25, "DV_X" => 5, "DV_B" => 17,
      "DV_M" => 16, "DV_W" => 54, "DV_V" => 55, "DV_Z" => 56,
      "KC_ENT" => 40, "KC_ESC" => 41, "KC_BSPC" => 42, "KC_TAB" => 43, "KC_SPC" => 44, "KC_CAPS" => 57,
      "KC_INS" => 73, "KC_HOME" => 74, "KC_PGUP" => 75, "KC_DEL" => 76, "KC_END" => 77, "KC_PGDN" => 78,
      "KC_RGHT" => 79, "KC_LEFT" => 80, "KC_DOWN" => 81, "KC_UP" => 82,
      "KC_LCTL" => 224, "KC_LSFT" => 225, "KC_LALT" => 226, "KC_LGUI" => 227,
      "KC_RCTL" => 228, "KC_RSFT" => 229, "KC_RALT" => 230, "KC_RGUI" => 231
    }.freeze
    SHIFTED = {
      "DV_TILD" => "DV_GRV", "DV_EXLM" => "DV_1", "DV_AT" => "DV_2", "DV_HASH" => "DV_3", "DV_DLR" => "DV_4",
      "DV_PERC" => "DV_5", "DV_CIRC" => "DV_6", "DV_AMPR" => "DV_7", "DV_ASTR" => "DV_8", "DV_LPRN" => "DV_9",
      "DV_RPRN" => "DV_0", "DV_LCBR" => "DV_LBRC", "DV_RCBR" => "DV_RBRC", "DV_DQUO" => "DV_QUOT",
      "DV_LABK" => "DV_COMM", "DV_RABK" => "DV_DOT", "DV_QUES" => "DV_SLSH", "DV_PLUS" => "DV_EQL",
      "DV_PIPE" => "DV_BSLS", "DV_UNDS" => "DV_MINS", "DV_COLN" => "DV_SCLN"
    }.freeze
    CONSUMER = {
      "KC_MPRV" => 0xb6, "KC_MNXT" => 0xb5, "KC_MPLY" => 0xcd, "KC_MUTE" => 0xe2, "KC_VOLU" => 0xe9,
      "KC_VOLD" => 0xea, "KC_BRIU" => 0x6f, "KC_BRID" => 0x70, "KC_MCTL" => 0x29f
    }.freeze
    LED = { "RM_NEXT" => :next, "RM_PREV" => :previous, "RM_TOGG" => :toggle }.freeze
    WRAPPERS = MODIFIERS.index_by { |mod| mod.to_s.upcase }.freeze
    MOD_TAPS = MODIFIERS.index_by { |mod| "#{mod.to_s.upcase}_T" }.freeze
    CALL = /\A(\w+)\((.*)\)\z/

    def initialize(layer_names)
      @layer_names = layer_names
    end

    def describe(expression)
      match = CALL.match(expression)
      match ? call(match[1], match[2]) : name(expression)
    end

    private

    def name(name)
      return [ :none ] if name == "KC_NO"
      return [ :transparent ] if name == "KC_TRNS"
      return [ :consumer, CONSUMER.fetch(name) ] if CONSUMER.key?(name)
      return [ :led, LED.fetch(name) ] if LED.key?(name)

      key(name)
    end

    def key(name)
      return [ :key, PLAIN.fetch(name), [] ] if PLAIN.key?(name)
      return with_modifier(:lsft, describe(SHIFTED.fetch(name))) if SHIFTED.key?(name)

      raise Error, "unknown QMK name #{name}"
    end

    def call(function, argument)
      return [ :layer, :momentary, layer(argument) ] if function == "MO"
      return [ :layer, :toggle, layer(argument) ] if function == "TG"
      return with_modifier(WRAPPERS.fetch(function), describe(argument)) if WRAPPERS.key?(function)
      return mod_tap(MOD_TAPS.fetch(function), describe(argument)) if MOD_TAPS.key?(function)

      raise Error, "unknown QMK name #{function}(#{argument})"
    end

    def layer(name)
      @layer_names.index(name) || raise(Error, "unknown QMK layer #{name}")
    end

    def with_modifier(mod, description)
      raise Error, "cannot add a modifier to #{description.inspect}" unless description.first == :key

      _, hid, mods = description
      [ :key, hid, (mods + [ mod ]).uniq.sort_by { |each| MODIFIERS.index(each) } ]
    end

    def mod_tap(mod, description)
      raise Error, "mod-tap needs a plain key, got #{description.inspect}" unless description in [ :key, _, [] ]

      [ :mod_tap, description[1], mod ]
    end
  end
end
