require 'helper'

describe RemoteTable do
  it "opens a shapefile" do
    t = RemoteTable.new 'http://www.nrel.gov/gis/cfm/data/GIS_Data_Technology_Specific/United_States/Solar/High_Resolution/Lower_48_DNI_High_Resolution.zip', :format => :shp, :crop => [5,5]
    t[0]['upper_corner_x'].must_equal -94.89999999999999
    t[0]['upper_corner_y'].must_equal 49.7
    t[0]['lower_corner_x'].must_equal -94.99999999999999
    t[0]['lower_corner_y'].must_equal 49.6
    t[0]['DNI01'].must_equal 1269.0
    t[0]['DNIANN'].must_equal 3315.0
  end
end
