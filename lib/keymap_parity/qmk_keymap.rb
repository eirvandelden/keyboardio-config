require "open3"

module KeymapParity
  # The QMK keymap as `qmk c2json` and `qmk info` report it, addressed by Kaleidoscope position.
  class QmkKeymap
    LAYER_COUNT = 4
    KEY_COUNT = 64
    KALEIDOSCOPE_POSITIONS = (0..3).to_a.product((0..15).to_a).freeze
    ENUM = /enum\s+layers\s*\{([^}]*)\}/m
    DESIGNATOR = /^\s*\[(\w+)\]\s*=\s*LAYOUT/

    # Runs a command and returns its output, or stops with what it printed.
    class Command
      def call(*args)
        stdout, stderr, status = Open3.capture3(*args)
        return stdout if status.success?

        raise Error, "#{args.join(" ")} failed (#{status.exitstatus}): #{stderr}#{stdout}"
      end
    end

    def self.load(keymap_path, keyboard: "keyboardio/model100", keymap: "eirvandelden", command: Command.new)
      layers = JSON.parse(command.call("qmk", "c2json", "-kb", keyboard, "-km", keymap, "--no-cpp", keymap_path))
      info = JSON.parse(command.call("qmk", "info", "-kb", keyboard, "-f", "json"))
      positions = info.dig("layouts", "LAYOUT", "layout").map { |key| key["matrix"] }
      new(layers.fetch("layers"), positions, File.read(keymap_path))
    end

    def initialize(layers, positions, source)
      positions = positions.map { |row, col| kaleidoscope(row, col) }
      check_shape(layers, positions)
      names = QmkNames.new(layer_names(source))
      @keys = layers.map { |layer| positions.zip(layer.map { |name| names.describe(name) }).to_h }
    end

    def layer_count
      @keys.size
    end

    def key(layer, row, col)
      @keys.fetch(layer).fetch([ row, col ])
    end

    private

    def kaleidoscope(row, col)
      row < 4 ? [ row, 7 - col ] : [ row - 4, 15 - col ]
    end

    def check_shape(layers, positions)
      raise Error, "expected #{LAYER_COUNT} QMK layers, got #{layers.size}" unless layers.size == LAYER_COUNT
      raise Error, "expected #{KEY_COUNT} LAYOUT positions, got #{positions.size}" unless positions.size == KEY_COUNT
      raise Error, "LAYOUT does not cover each key position exactly once" unless positions.sort == KALEIDOSCOPE_POSITIONS

      layers.each_with_index do |layer, index|
        raise Error, "QMK layer #{index} has #{layer.size} keys, expected #{KEY_COUNT}" unless layer.size == KEY_COUNT
      end
    end

    def layer_names(source)
      declared = ENUM.match(source)&.captures&.first or raise Error, "no enum layers in keymap.c"
      names = declared.split(",").map(&:strip).reject(&:empty?)
      return names if source.scan(DESIGNATOR).flatten == names

      raise Error, "layers in keymap.c are not in the order of the enum layers declaration"
    end
  end
end
