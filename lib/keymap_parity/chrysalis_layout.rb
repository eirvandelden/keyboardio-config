module KeymapParity
  # Reads the Chrysalis export and describes the key at a layer and Kaleidoscope position.
  class ChrysalisLayout
    KEYS_PER_ROW = 16
    FLAG_MODIFIERS = { 0x100 => :lctl, 0x200 => :lalt, 0x400 => :ralt, 0x800 => :lsft, 0x1000 => :lgui }.freeze
    TRANSPARENT = 65_535
    DUAL_USE = 49_169..(49_169 + 0x7ff)
    LED = { 17_152 => :next, 17_153 => :previous, 17_154 => :toggle }.freeze
    LOCK = 17_408...17_450
    SHIFT = 17_450...17_492
    CONSUMER = 0x4800..0x4bff

    def self.load(path)
      new(KeymapParity.parse_json(File.read(path), path))
    end

    def initialize(layout)
      @layers = layout.fetch("keymaps")
    end

    def layer_count
      @layers.size
    end

    def key(layer, row, col)
      describe(@layers.fetch(layer).fetch(row * KEYS_PER_ROW + col).fetch("code"))
    end

    private

    def describe(code)
      return [ :none ] if code.zero?
      return [ :transparent ] if code == TRANSPARENT
      return plain(code) if code < 0x2000
      return dual_use(code) if DUAL_USE.cover?(code)
      return [ :consumer, code & 0x03ff ] if CONSUMER.cover?(code)

      special(code)
    end

    def plain(code)
      mods = FLAG_MODIFIERS.filter_map { |flag, mod| mod if code & flag != 0 }
      [ :key, code & 0xff, mods.sort_by { |mod| MODIFIERS.index(mod) } ]
    end

    def dual_use(code)
      value = code - DUAL_USE.begin
      [ :mod_tap, value & 0xff, MODIFIERS.fetch(value >> 8) ]
    end

    def special(code)
      return [ :led, LED.fetch(code) ] if LED.key?(code)
      return [ :layer, :toggle, target(code - LOCK.begin) ] if LOCK.cover?(code)
      return [ :layer, :momentary, target(code - SHIFT.begin) ] if SHIFT.cover?(code)

      raise Error, "unknown Chrysalis code #{code}"
    end

    def target(layer)
      LAYER_PAIRS.fetch(layer) { raise Error, "layer key targets layer #{layer}, which the QMK keymap does not have" }
    end
  end
end
