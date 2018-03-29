require "box_generator/version"

class BoxGenerator

  attr_accessor :settings

  def initialize(settings = {})
    self.settings = settings
  end

  def to_scad
    <<-SCAD
#{comments}

#{header}

difference() {
  #{main_cube}
  #{compartiments}
}
    SCAD
  end

private

  %w(
    external_walls_depth
    internal_walls_depth
    floor_depth
    top_margin
    compartiment_x
    compartiment_z
    compartiments_y
  ).each do |setting_name|
    define_method(setting_name) do
      settings[setting_name]
    end
  end

  def external_x
    compartiment_x + external_walls_depth * 2
  end

  def external_y
    external_walls_depth * 2 + compartiments_y.inject(&:+) + (compartiments_y.size - 1) * internal_walls_depth
  end

  def external_z
    compartiment_z + floor_depth + top_margin
  end

  def comments
    <<-COMMENTS
// Source: https://github.com/carlosparamio/box_generator
// Settings: #{settings.inspect}
    COMMENTS
  end

  def header
    <<-HEADER
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

  def main_cube
    "cube([#{external_x}, #{external_y}, #{external_z}]);"
  end

  def compartiments
    compartiments = ""
    compartiments_y_subtotal = 0
    compartiments_y.each_with_index do |compartiment_y, index|
      compartiments += "translate([#{external_walls_depth}, #{external_walls_depth + internal_walls_depth * index + compartiments_y_subtotal}, #{floor_depth}]) mirror([0, 1, 0]) rotate([90, 0, 0]) roundedcube(#{compartiment_x}, #{compartiment_z * 2}, #{compartiment_y}, #{compartiment_x / 5});"
      compartiments_y_subtotal += compartiment_y
    end
    compartiments
  end

end