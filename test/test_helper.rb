require "minitest/autorun"
require "keymap_parity"

module ChrysalisFixtures
  TRANSPARENT = 65_535

  def chrysalis_layout(overrides = {})
    layers = Array.new(8) { Array.new(64) { { "code" => TRANSPARENT } } }
    overrides.each { |(layer, index), code| layers[layer][index] = { "code" => code } }
    KeymapParity::ChrysalisLayout.new("keymaps" => layers)
  end
end
