module KeymapParity
  # Walks every layer and position and lists where Chrysalis and QMK disagree.
  class Comparison
    CHRYSALIS_LAYERS = 8
    LAYER_PAIRS = { 0 => 0, 1 => 1, 2 => 2, 4 => 3 }.freeze
    UNUSED_LAYERS = [ 3, 5, 6, 7 ].freeze
    MISSION_CONTROL = { layer: 0, position: [ 1, 6 ], chrysalis: [ :consumer, 0x2a2 ], qmk: [ :consumer, 0x29f ] }.freeze

    Difference = Struct.new(:where, :chrysalis, :qmk) do
      def to_s
        "#{where}: Chrysalis #{chrysalis.inspect}, QMK #{qmk.inspect}"
      end
    end

    def initialize(chrysalis, qmk)
      raise Error, "expected #{CHRYSALIS_LAYERS} Chrysalis layers, got #{chrysalis.layer_count}" unless chrysalis.layer_count == CHRYSALIS_LAYERS

      @chrysalis = chrysalis
      @qmk = qmk
    end

    def differences
      paired_differences + unused_differences
    end

    def report
      differences.map(&:to_s)
    end

    private

    def paired_differences
      LAYER_PAIRS.flat_map do |chrysalis_layer, qmk_layer|
        positions.filter_map { |row, col| paired(chrysalis_layer, qmk_layer, row, col) }
      end
    end

    def paired(chrysalis_layer, qmk_layer, row, col)
      expected = @chrysalis.key(chrysalis_layer, row, col)
      actual = @qmk.key(qmk_layer, row, col)
      return if expected == actual || exception?(qmk_layer, [ row, col ], expected, actual)

      Difference.new("Chrysalis layer #{chrysalis_layer} / QMK layer #{qmk_layer} #{label(row, col)}", expected, actual)
    end

    def exception?(layer, position, expected, actual)
      return false unless layer.zero?

      transparent_for_nothing?(expected, actual) || mission_control?(position, expected, actual)
    end

    def transparent_for_nothing?(expected, actual)
      expected == [ :transparent ] && actual == [ :none ]
    end

    def mission_control?(position, expected, actual)
      [ position, expected, actual ] == MISSION_CONTROL.values_at(:position, :chrysalis, :qmk)
    end

    def unused_differences
      UNUSED_LAYERS.flat_map do |layer|
        positions.filter_map { |row, col| unused(layer, row, col) }
      end
    end

    def unused(layer, row, col)
      found = @chrysalis.key(layer, row, col)
      return if found == [ :transparent ]

      Difference.new("Chrysalis layer #{layer} #{label(row, col)}", found, "expected an empty layer")
    end

    def positions
      QmkKeymap::KALEIDOSCOPE_POSITIONS
    end

    def label(row, col)
      "r#{row}c#{col}"
    end
  end
end
