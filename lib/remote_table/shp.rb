class RemoteTable
  # Mixed in to process SHP with the georuby library.
  module Shp
    def _each
      require 'geo_ruby'

      shp = Dir[File.join(local_copy.path, '*.shp')].first
      GeoRuby::Shp4r::ShpFile.open(shp) do |shapefile|
        first_row = if crop
          crop.first
        else
          skip
        end
        last_row = if crop
          crop.last
        else
          shapefile.records.length
        end

        (first_row..last_row).each do |row_num|
          hsh = {}
          row = shapefile.records[row_num]

          row.data.attributes.each do |name, value|
            hsh[name] = value
          end

          envelope = row.geometry.envelope
          hsh['center'] = envelope.center
          hsh['upper_corner'] = {
            'x' => envelope.upper_corner.x,
            'y' => envelope.upper_corner.y,
          }
          hsh['lower_corner'] = {
            'x' => envelope.lower_corner.x,
            'y' => envelope.lower_corner.y,
          }

          yield hsh
        end
      end
    ensure
      local_copy.cleanup
    end
  end
end
