class BoxGenerator
  # Generates a set of objects that would dig custom compartiments on a
  # solid block given a set of parameters.
  #
  # @param settings [Hash] settings that the digger will use.
  #
  # Settings hash format:
  #
  # @param compartiments_separation [Integer] compartiments_separation in mm between compartiments
  # @param compartiments [Array] list of compartiment settings, like:
  #
  #   [
  #     [
  #       compartiment_1_x_mm,
  #       compartiment_1_y_mm,
  #       compartiment_1_z_mm,
  #       compartiment_1_curved_floor_boolean
  #     ],
  #     [
  #       compartiment_2_x_mm,
  #       compartiment_2_y_mm,
  #       compartiment_2_z_mm,
  #       compartiment_2_curved_floor_boolean
  #     ]
  #   ]
  class CompartimentsDigger

    attr_accessor :settings

    def initialize(settings = {})
      self.settings = settings
    end

    %w(
      compartiments_separation
      compartiments
    ).each do |setting_name|
      define_method(setting_name) do
        settings[setting_name]
      end
    end

    def compartiments_x
      compartiments.map{|c| c[0]}
    end

    def compartiments_y
      compartiments.map{|c| c[1]}
    end

    def compartiments_z
      compartiments.map{|c| c[2]}
    end

    def external_x
      compartiments_x.max
    end

    def external_y
      compartiments_y.sum + compartiments_separation * (compartiments.size - 1)
    end

    def external_z
      compartiments_z.max
    end

    def flat_compartiment(x, y, z)
      <<-FLAT.strip_heredoc
        cube([#{x}, #{y}, #{z}]);
      FLAT
    end

    def curved_compartiment(x, y, z)
      <<-CURVED.strip_heredoc
        mirror([0, 1, 0]) {
          rotate([90, 0, 0]) {
            roundedcube(#{x}, #{z * 2}, #{y}, #{x / 5});
          }
        }
      CURVED
    end

    def to_scad
      result = ""
      y_shift = 0
      compartiments.each do |x, y, z, curved|
        result += <<-SCAD.strip_heredoc
          translate([
            0,
            #{y_shift},
            #{external_z - z}
          ]) {
            #{curved ? curved_compartiment(x, y, z) : flat_compartiment(x, y, z)}
          }
        SCAD
        y_shift += y + compartiments_separation
      end
      result
    end

  end
end