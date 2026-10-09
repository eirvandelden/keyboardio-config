require "minitest/autorun"
require "json"
require "keymap_parity"

module ChrysalisFixtures
  TRANSPARENT = 65_535

  def chrysalis_layout(overrides = {})
    layers = Array.new(8) { Array.new(64) { { "code" => TRANSPARENT } } }
    overrides.each { |(layer, index), code| layers[layer][index] = { "code" => code } }
    KeymapParity::ChrysalisLayout.new("keymaps" => layers)
  end
end

module QmkFixtures
  LAYER_NAMES = %w[BASE NUMBERS NAVIGATION MEDIA].freeze
  INFO = File.expand_path("keymap_parity/fixtures/qmk_info.json", __dir__)

  def layout_positions
    JSON.parse(File.read(INFO)).dig("layouts", "LAYOUT", "layout").map { |key| key["matrix"] }
  end

  def keymap_source
    designators = LAYER_NAMES.map { |name| "  [#{name}] = LAYOUT(...)," }.join("\n")
    "enum layers { #{LAYER_NAMES.join(", ")} };\nconst uint16_t keymaps[] = {\n#{designators}\n};\n"
  end

  # overrides: { [layer, layout_index] => "QMK_NAME" }
  def qmk_keymap(overrides = {}, layers: 4, source: keymap_source, positions: layout_positions)
    names = Array.new(layers) { |layer| Array.new(positions.size) { layer.zero? ? "KC_NO" : "KC_TRNS" } }
    overrides.each { |(layer, index), name| names[layer][index] = name }
    KeymapParity::QmkKeymap.new(names, positions, source)
  end
end
