class RemoteTable
  # Mixed in to process SHP with the georuby library.
  module Shp
    def _each
      require 'geo_ruby'
      require 'geo_ruby/shp4r/shp'

      shp = Dir[File.join(local_copy.path, '*.shp')].first
      GeoRuby::Shp4r::ShpFile.open(shp) do |shapefile|
        shapefile.each do |row|
          hsh = {}
          row.data.attributes.each do |name, value|
            hsh[name] = value
          end

          envelope = row.geometry.envelope
          hsh['center'] = envelope.center
          hsh['upper_corner_x'] = envelope.upper_corner.x
          hsh['upper_corner_y'] = envelope.upper_corner.y
          hsh['lower_corner_x'] = envelope.lower_corner.x
          hsh['lower_corner_y'] = envelope.lower_corner.y

          yield hsh
        end
      end
    ensure
      local_copy.cleanup
    end
  end
end
