require "box_generator/version"
require "box_generator/compartiments_digger"
require "core_ext/string"

# Generates a custom box with parameterized compartiments, each with
# optional curved surface, and with optional magnet holes.
#
# == Parameters:
# settings::
#   A Hash with the settings to build the box.
class BoxGenerator

  attr_accessor :settings

  def initialize(settings = {})
    self.settings = settings
  end

  %w(
    external_walls
    compartiments_separation
    floor
    compartiments
    magnets_height
    magnets_diameter
  ).each do |setting_name|
    define_method(setting_name) do
      settings[setting_name]
    end
  end

  def external_x
    internal_x + external_walls * 2
  end

  def external_y
    internal_y + external_walls * 2
  end

  def external_z
    internal_z + floor
  end

  def internal_x
    compartiment_diggers.sum do |compartiments_digger|
      compartiments_digger.external_x
    end + (compartiment_diggers.size - 1) * compartiments_separation
  end

  def internal_y
    compartiment_diggers.map do |compartiments_digger|
      compartiments_digger.external_y
    end.max
  end

  def internal_z
    compartiment_diggers.map do |compartiments_digger|
      compartiments_digger.external_z
    end.max
  end

  def magnets?
    magnets_height > 0 && magnets_diameter > 0
  end

  def comments_scad
    <<-COMMENTS.strip_heredoc
      // Source: https://github.com/carlosparamio/box_generator
      // Settings: #{settings.inspect}
    COMMENTS
  end

  def header_scad
    <<-HEADER.strip_heredoc
      module roundedcube(xdim, ydim, zdim, rdim) {
        hull() {
          translate([rdim, rdim, 0]) cylinder(h = zdim, r = rdim);
          translate([xdim - rdim, rdim, 0]) cylinder(h = zdim, r = rdim);
          translate([rdim, ydim - rdim, 0]) cylinder(h = zdim, r = rdim);
          translate([xdim - rdim, ydim - rdim, 0]) cylinder(h = zdim, r = rdim);
        }
      }
    HEADER
  end

  def main_cube_scad
    "cube([#{external_x}, #{external_y}, #{external_z}]);"
  end

  def compartiment_diggers
    compartiments.map do |compartiments_row|
      CompartimentsDigger.new(
        "compartiments_separation" => compartiments_separation,
        "compartiments"            => compartiments_row
      )
    end
  end

  def compartiments_scad
    result  = ""
    x_shift = external_walls
    compartiment_diggers.each do |compartiments_digger|
      result += <<-COMPARTIMENTS_DIGGER
        translate([
          #{x_shift},
          #{external_walls},
          #{external_z - compartiments_digger.external_z}
        ]) {
          #{compartiments_digger.to_scad};
        }
      COMPARTIMENTS_DIGGER
      x_shift += compartiments_digger.external_x + compartiments_separation
    end
    result
  end

  def magnets_scad
    <<-MAGNETS.strip_heredoc
      translate([
        #{external_walls / 2},
        #{external_walls / 2},
        #{external_z - magnets_height + 1}
      ]) {
        cylinder(#{magnets_height}, d = #{magnets_diameter}, $fn = 100);
      }

      translate([
        #{external_x - external_walls / 2},
        #{external_walls / 2},
        #{external_z - magnets_height + 1}
      ]) {
        cylinder(#{magnets_height}, d = #{magnets_diameter}, $fn = 100);
      }

      translate([
        #{external_walls / 2},
        #{external_y - external_walls / 2},
        #{external_z - magnets_height + 1}
      ]) {
        cylinder(#{magnets_height}, d = #{magnets_diameter}, $fn = 100);
      }

      translate([
        #{external_x - external_walls / 2},
        #{external_y - external_walls / 2},
        #{external_z - magnets_height + 1}
      ]) {
        cylinder(#{magnets_height}, d = #{magnets_diameter}, $fn = 100);
      }
    MAGNETS
  end

  def to_scad
    <<-SCAD.strip_heredoc
      #{comments_scad}

      #{header_scad}

      difference() {
        #{main_cube_scad}
        #{compartiments_scad}
        #{magnets_scad if magnets?}
      }
    SCAD
  end

end