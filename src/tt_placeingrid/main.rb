require 'sketchup.rb'

module TT::Plugins::PlaceInGrid

  unless file_loaded?(__FILE__)
    menu = UI.menu('Plugins')
    menu.add_item('Place in Grid...') { self.place_in_grid }
    file_loaded(__FILE__)
  end

  def self.center_by_bounds_in_tile(tile_origin, tile_size, instance)
    half_tile = tile_size / 2
    tile_center = Geom::Vector3d.new(half_tile, half_tile, 0)

    bounds = instance.bounds
    w = bounds.width / 2
    h = bounds.height / 2
    bounds_center = Geom::Vector3d.new(-w, -h, 0)

    front_left_bottom_corner = bounds.corner(0)
    x = front_left_bottom_corner.x
    y = front_left_bottom_corner.y
    z = front_left_bottom_corner.z
    bounds_origin = Geom::Vector3d.new(x, y, z).reverse

    tile_origin.offset!(tile_center).offset!(bounds_origin).offset!(bounds_center)
  end

  def self.place_in_grid
    debug = true

    model = Sketchup.active_model
    entities = model.active_entities

    instances = entities.select { |entity|
      entity.is_a?(Sketchup::Group) || entity.is_a?(Sketchup::ComponentInstance)
    }

    puts "Instances: #{instances.size}" if debug

    center_by_bounds = true

    tile_size = 2.m

    grid_tiles = Math.sqrt(instances.size).ceil
    grid_length = tile_size * grid_tiles

    puts "Grid Tiles: #{grid_tiles}" if debug
    puts "Grid Length: #{grid_length}" if debug


    model.start_operation('Place in Grid', true)

    model.rendering_options['DisplayInstanceAxes'] = true

    (0..grid_tiles).each { |x|
      pt1 = Geom::Point3d.new(x * tile_size, 0, 0)
      pt2 = Geom::Point3d.new(x * tile_size, grid_length, 0)
      entities.add_line(pt1, pt2)
    }

    (0..grid_tiles).each { |y|
      pt1 = Geom::Point3d.new(0, y * tile_size, 0)
      pt2 = Geom::Point3d.new(grid_length, y * tile_size, 0)
      entities.add_line(pt1, pt2)
    }

    instances.each_with_index { |instance, i|
      x = (i % grid_tiles) * tile_size
      y = (i / grid_tiles) * tile_size
      origin = Geom::Point3d.new(x, y, 0)

      self.center_by_bounds_in_tile(origin, tile_size, instance) if center_by_bounds

      tr = Geom::Transformation.new(origin)
      instance.transformation = tr
    }

    model.commit_operation
  end

end # module
