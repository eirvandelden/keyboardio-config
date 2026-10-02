module KeymapParity
  class Error < StandardError; end

  MODIFIERS = %i[lctl lsft lalt lgui rctl rsft ralt rgui].freeze
  # Chrysalis layer number => QMK layer number, for the layers the QMK keymap keeps.
  LAYER_PAIRS = { 0 => 0, 1 => 1, 2 => 2, 4 => 3 }.freeze
end

require "json"
require "keymap_parity/chrysalis_layout"
require "keymap_parity/qmk_names"
require "keymap_parity/qmk_keymap"
require "keymap_parity/comparison"
