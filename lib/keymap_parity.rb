module KeymapParity
  class Error < StandardError; end

  MODIFIERS = %i[lctl lsft lalt lgui rctl rsft ralt rgui].freeze
end

require "json"
require "keymap_parity/chrysalis_layout"
require "keymap_parity/qmk_names"
require "keymap_parity/qmk_keymap"
require "keymap_parity/comparison"
