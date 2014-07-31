# remote_table

Open Google Docs spreadsheets, local or remote XLSX, XLS, ODS, CSV (comma separated), TSV (tab separated), other delimited, fixed-width files.

Tested on MRI 1.8, MRI 1.9, and JRuby 1.6.7+. Thread-safe.

## Real-world usage

<p><a href="http://brighterplanet.com"><img src="https://s3.amazonaws.com/static.brighterplanet.com/assets/logos/flush-left/inline/green/rasterized/brighter_planet-160-transparent.png" alt="Brighter Planet logo"/></a></p>

We use `remote_table` for [data science at Brighter Planet](http://brighterplanet.com/research) and in production at

* [Brighter Planet's impact estimate web service](http://impact.brighterplanet.com)
* [Brighter Planet's reference data web service](http://data.brighterplanet.com)

It's also a big part of

* the [`data_miner`](https://github.com/seamusabshere/data_miner) library
* the [`earth`](https://github.com/brighterplanet/earth) library

## Example

    >> require 'remote_table'
    => true
    >> t = RemoteTable.new 'http://www.fueleconomy.gov/FEG/epadata/98guide6.zip', :filename => '98guide6.csv'
    => #<RemoteTable:0x00000101b87390 @download_count_mutex=#<Mutex:0x00000101b87228>, @extend_bang_mutex=#<Mutex:0x00000101b871d8>, @errata_mutex=#<Mutex:0x00000101b871b0>, @cache=[], @download_count=0, @url="http://www.fueleconomy.gov/FEG/epadata/98guide6.zip", @format=nil, @headers=:first_row, @compression=:zip, @packing=nil, @streaming=false, @warn_on_multiple_downloads=true, @delimiter=",", @sheet=nil, @keep_blank_rows=false, @form_data=nil, @skip=0, @internal_encoding="UTF-8", @row_xpath=nil, @column_xpath=nil, @row_css=nil, @column_css=nil, @glob=nil, @filename="98guide6.csv", @transform_settings=nil, @cut=nil, @crop=nil, @schema=nil, @schema_name=nil, @pre_select=nil, @pre_reject=nil, @errata_settings=nil, @other_options={}, @transformer=#<RemoteTable::Transformer:0x00000101b8c2f0 @t=#<RemoteTable:0x00000101b87390 ...>, @legacy_transformer_mutex=#<Mutex:0x00000101b8c2a0>>, @local_copy=#<RemoteTable::LocalCopy:0x00000101b8bf58 @t=#<RemoteTable:0x00000101b87390 ...>, @encoded_io_mutex=#<Mutex:0x00000101b8be18>, @generate_mutex=#<Mutex:0x00000101b8bdc8>>>
    >> t.rows.length
    => 806
    >> t.rows.first.length
    => 26
    >> require 'pp'
    => true
    >> pp t[23]
    {"Class"=>"TWO SEATERS",
     "Manufacturer"=>"PORSCHE",
     "carline name"=>"BOXSTER",
     "displ"=>"2.5",
     "cyl"=>"6",
     "trans"=>"Manual(M5)",
     "drv"=>"R",
     "cty"=>"19",
     "hwy"=>"26",
     "cmb"=>"22",
     "ucty"=>"21.2",
     "uhwy"=>"33.9499",
     "ucmb"=>"25.5114",
     "fl"=>"P",
     "G"=>"",
     "T"=>"",
     "S"=>"",
     "2pv"=>"",
     "2lv"=>"",
     "4pv"=>"",
     "4lv"=>"",
     "hpv"=>"",
     "hlv"=>"",
     "fcost"=>"956",
     "eng dscr"=>"",
     "trans dscr"=>""}

## Columns and rows

* If there are headers, you get an <code>Array</code> of <code>Hash</code>es with **string keys**.
* If you set <code>:headers => false</code>, then you get an <code>Array</code> of <code>Array</code>s.

## Row keys

Row keys are **strings**. Row keys are NOT symbolized.

    row['foobar'] # correct
    row[:foobar]  # incorrect

You can call <code>symbolize_keys</code> yourself, but we don't do it automatically to avoid creating loads of garbage symbols.

## Supported formats

<table>
  <tr>
    <th>Format</th>
    <th>Notes</th>
    <th>Library</th>
  </tr>
  <tr>
    <td>Delimited (CSV, TSV, etc.)</td>
    <td>All <code>RemoteTable::Delimited::PASSTHROUGH_CSV_SETTINGS</code>, for example <code>:col_sep</code>, are passed directly to fastercsv.</td>
    <td>
      <a href="http://fastercsv.rubyforge.org/">fastercsv</a> (1.8);
      <a href="http://www.ruby-doc.org/stdlib-1.9.3/libdoc/csv/rdoc/index.html">stdlib</code></a> (1.9)
    </td>
  </tr>
  <tr>
    <td>Fixed width</td>
    <td>You have to set up a <code>:schema</code>.</td>
    <td><a href="https://github.com/seamusabshere/fixed_width">fixed_width-multibyte</a></td>
  </tr>
  <tr>
    <td>HTML</td>
    <td>See XML.</td>
    <td><a href="http://nokogiri.org/">nokogiri</a></td>
  </tr>
  <tr>
    <td>ODS</td>
    <td></td>
    <td><a href="http://roo.rubyforge.org/">roo</a></td>
  </tr>
  <tr>
    <td>XLS</td>
    <td></td>
    <td><a href="http://roo.rubyforge.org/">roo</a></td>
  </tr>
  <tr>
    <td>XLSX</td>
    <td></td>
    <td><a href="http://roo.rubyforge.org/">roo</a></td>
  </tr>
  <tr>
    <td>XML</td>
    <td>The idea is to set up a <code>:row_[xpath|css]</code> and (optionally) a <code>:column_[xpath|css]</code>.</td>
    <td><a href="http://nokogiri.org/">nokogiri</a></td>
  </tr>
  <tr>
    <td>JSON</td>
    <td>Force JSON format using <code>format: :json</code> and define root nodes using <code>root_node: 'data'</code></td>
    <td><a href="http://www.ruby-doc.org/stdlib-2.0.0/libdoc/json/rdoc/JSON.html">JSON</a></td>
  </tr>
</table>

## Compression and packing

You can directly pick a file out of a remote archive using <code>:filename</code> or use a <code>:glob</code>.

* zip
* tar
* bz2
* gz
* exe (treated as zip)

## Encoding

Everything is forced into UTF-8. You can improve the quality of the conversion by specifying the original encoding with `:encoding`

* ASCII-8BIT and BINARY are equal
* ISO-8859-1 and Latin1 are equal

## More examples

    RemoteTable.new('https://spreadsheets.google.com/pub?key=0AoQJbWqPrREqdHRNaVpSUWw2Z2VhN3RUV25yYWdQX2c&output=csv')

    # aircraft fuel use equations derived from EMEP/EEA and ICAO
    RemoteTable.new('https://docs.google.com/spreadsheet/pub?key=0AoQJbWqPrREqdEhYenF3dGt1T0Y1cTdneUNsNjV0dEE&output=csv')

    # distance classes from the WRI business travel tool and UK DEFRA/DECC GHG Conversion Factors for Company Reporting
    RemoteTable.new('https://spreadsheets.google.com/pub?key=0AoQJbWqPrREqdFBKM0xWaUhKVkxDRmdBVkE3VklxY2c&hl=en&gid=0&output=csv')

    # seat classes used in the WRI GHG Protocol calculation tools
    RemoteTable.new('https://docs.google.com/spreadsheet/pub?key=0AoQJbWqPrREqdG9EdmxybG1wdC1iU3JRYXNkMGhvSnc&output=csv')

    # pure automobile fuels
    RemoteTable.new('https://spreadsheets.google.com/pub?key=0AoQJbWqPrREqdE9xTEdueFM2R0diNTgxUlk1QXFSb2c&gid=0&output=csv')

    # blended automobile fuels
    RemoteTable.new('https://spreadsheets.google.com/pub?key=0AoQJbWqPrREqdEswNGIxM0U4U0N1UUppdWw2ejJEX0E&gid=0&output=csv')

    # A list of hybrid make model years derived from the EPA fuel economy guide
    RemoteTable.new('https://docs.google.com/spreadsheet/pub?hl=en_US&hl=en_US&key=0AoQJbWqPrREqdGtzekE4cGNoRGVmdmZMaTNvOWluSnc&output=csv')

    # BTS aircraft type lookup table
    RemoteTable.new("http://www.transtats.bts.gov/Download_Lookup.asp?Lookup=L_AIRCRAFT_TYPE",
                    :errata => { :url => RemoteTable.new('https://spreadsheets.google.com/spreadsheet/pub?key=0AoQJbWqPrREqdEZ2d3JQMzV5T1o1T3JmVlFyNUZxdEE&output=csv' })

    # aircraft made by whitelisted manufacturers whose ICAO code starts with 'B' from the FAA
    # for definition of `Aircraft::Guru` and `manufacturer_whitelist?` see https://github.com/brighterplanet/earth/blob/master/lib/earth/air/aircraft/data_miner.rb
    RemoteTable.new("http://www.faa.gov/air_traffic/publications/atpubs/CNT/5-2-B.htm",
                    :encoding => 'windows-1252',
                    :row_xpath => '//table/tr[2]/td/table/tr',
                    :column_xpath => 'td',
                    :errata => { :url => 'https://spreadsheets.google.com/spreadsheet/pub?key=0AoQJbWqPrREqdGVBRnhkRGhSaVptSDJ5bXJGbkpUSWc&output=csv', :responder => Aircraft::Guru.new },
                    :select => proc { |record| manufacturer_whitelist? record['Manufacturer'] })

    # OpenFlights.org airports database
    RemoteTable.new('https://openflights.svn.sourceforge.net/svnroot/openflights/openflights/data/airports.dat',
                    :headers => %w{ id name city country_name iata_code icao_code latitude longitude altitude timezone daylight_savings },
                    :select => proc { |record| record['iata_code'].present? },
                    :errata => { :url => RemoteTable.new('https://spreadsheets.google.com/pub?key=0AoQJbWqPrREqdFc2UzhQYU5PWEQ0N21yWFZGNmc2a3c&gid=0&output=csv', :responder => Airport::Guru.new }) # see https://github.com/brighterplanet/earth/blob/master/lib/earth/air/aircraft/data_miner.rb

    # T100 flight segment data for #{month.strftime('%B %Y')}
    # for definition of `form_data` and `FlightSegment::Guru` see https://github.com/brighterplanet/earth/blob/master/lib/earth/air/flight_segment/data_miner.rb
    RemoteTable.new('http://www.transtats.bts.gov/DownLoad_Table.asp',
                    :form_data => form_data,
                    :compression => :zip,
                    :glob => '/*.csv',
                    :errata => { :url => RemoteTable.new('https://spreadsheets.google.com/spreadsheet/pub?key=0AoQJbWqPrREqdGxpYU1qWFR3d0syTVMyQVVOaDd0V3c&output=csv', :responder => FlightSegment::Guru.new },
                    :select => proc { |record| record['DEPARTURES_PERFORMED'].to_i > 0 })

    # 1995 Fuel Economy Guide
    # for definition of `:fuel_economy_guide_b` and `AutomobileMakeModelYearVariant::ParserB` see https://github.com/brighterplanet/earth/blob/master/lib/earth/automobile/automobile_make_model_year_variant/data_miner.rb
    RemoteTable.new("http://www.fueleconomy.gov/FEG/epadata/95mfgui.zip",
                    :filename => '95MFGUI.DAT',
                    :format => :fixed_width,
                    :cut => '13-',
                    :schema_name => :fuel_economy_guide_b,
                    :select => proc { |row| row['model'].present? and (row['suppress_code'].blank? or row['suppress_code'].to_f == 0) and row['state_code'] == 'F' },
                    :transform => { :class => AutomobileMakeModelYearVariant::ParserB, :year => 1995 },
                    :errata => { :url => "https://docs.google.com/spreadsheet/pub?key=0AoQJbWqPrREqdDkxTElWRVlvUXB3Uy04SDhSYWkzakE&output=csv", :responder => AutomobileMakeModelYearVariant::Guru.new })

    # 1998 Fuel Economy Guide
    # for definition of `AutomobileMakeModelYearVariant::ParserC` see https://github.com/brighterplanet/earth/blob/master/lib/earth/automobile/automobile_make_model_year_variant/data_miner.rb
    RemoteTable.new('http://www.fueleconomy.gov/FEG/epadata/98guide6.zip',
                    :filename => '98guide6.csv',
                    :transform => { :class => AutomobileMakeModelYearVariant::ParserC, :year => 1998 },
                    :errata => { :url => "https://docs.google.com/spreadsheet/pub?key=0AoQJbWqPrREqdDkxTElWRVlvUXB3Uy04SDhSYWkzakE&output=csv", :responder => AutomobileMakeModelYearVariant::Guru.new },
                    :select => proc { |row| row['model'].present? })

    # annual corporate average fuel economy data for domestic and imported vehicle fleets from the NHTSA
    RemoteTable.new('https://spreadsheets.google.com/pub?key=0AoQJbWqPrREqdEdXWXB6dkVLWkowLXhYSFVUT01sS2c&hl=en&gid=0&output=csv',
                    :errata => { 'url' => 'http://static.brighterplanet.com/science/data/transport/automobiles/make_fleet_years/errata.csv' },
                    :select => proc { |row| row['volume'].to_i > 0 })

    # total vehicle miles travelled by gasoline passenger cars from the 2010 EPA GHG Inventory
    RemoteTable.new('http://www.epa.gov/climatechange/emissions/downloads10/2010-Inventory-Annex-Tables.zip',
                    :filename => 'Annex Tables/Annex 3/Table A-87.csv',
                    :skip => 1,
                    :select => proc { |row| row['Year'].to_i.to_s == row['Year'] })

    # total vehicle miles travelled from the 2010 EPA GHG Inventory
    RemoteTable.new('http://www.epa.gov/climatechange/emissions/downloads10/2010-Inventory-Annex-Tables.zip',
                    :filename => 'Annex Tables/Annex 3/Table A-87.csv',
                    :skip => 1,
                    :select => proc { |row| row['Year'].to_i.to_s == row['Year'] })

    # total travel distribution from the 2010 EPA GHG Inventory
    RemoteTable.new('http://www.epa.gov/climatechange/emissions/downloads10/2010-Inventory-Annex-Tables.zip',
                    :filename => 'Annex Tables/Annex 3/Table A-93.csv',
                    :skip => 1,
                    :select => proc { |row| row['Vehicle Age'].to_i.to_s == row['Vehicle Age'] })

    # building characteristics from the 2003 EIA Commercial Building Energy Consumption Survey
    RemoteTable.new('http://www.eia.gov/emeu/cbecs/cbecs2003/public_use_2003/data/FILE02.csv',
                    :skip => 1,
                    :headers => ["PUBID8","REGION8","CENDIV8","SQFT8","SQFTC8","YRCONC8","PBA8","ELUSED8","NGUSED8","FKUSED8","PRUSED8","STUSED8","HWUSED8","ONEACT8","ACT18","ACT28","ACT38","ACT1PCT8","ACT2PCT8","ACT3PCT8","PBAPLUS8","VACANT8","RWSEAT8","PBSEAT8","EDSEAT8","FDSEAT8","HCBED8","NRSBED8","LODGRM8","FACIL8","FEDFAC8","FACACT8","MANIND8","PLANT8","FACDST8","FACDHW8","FACDCW8","FACELC8","BLDPLT8","ADJWT8","STRATUM8","PAIR8"])

    # 2003 CBECS C17 - Electricity Consumption and Intensity - New England Division
    # for definition of `CbecsEnergyIntensity::NAICS_CODE_SYNTHESIZER` see https://github.com/brighterplanet/earth/blob/master/lib/earth/industry/cbecs_energy_intensity/data_miner.rb
    RemoteTable.new("http://www.eia.gov/emeu/cbecs/cbecs2003/detailed_tables_2003/2003set10/2003excel/C17.xls",
                    :headers => false,
                    :select => proc { |row| CbecsEnergyIntensity::NAICS_CODE_SYNTHESIZER.call(row) },
                    :crop => (21..37))

    # U.S. Census 2002 NAICS code list
    RemoteTable.new('http://www.census.gov/epcd/naics02/naicod02.txt',
                    :skip => 4,
                    :headers => false,
                    :delimiter => '	')

    # MECS table 3.2 Total US
    RemoteTable.new("http://205.254.135.24/emeu/mecs/mecs2006/excel/Table3_2.xls",
                    :crop => (15..94),
                    :headers => ["NAICS Code", "Subsector and Industry", "Total", "BLANK", "Net Electricity", "BLANK", "Residual Fuel Oil", "Distillate Fuel Oil", "Natural Gas", "BLANK", "LPG and NGL", "BLANK", "Coal", "Coke and Breeze", "Other"])

    # MECS table 6.1 Midwest
    RemoteTable.new("http://205.254.135.24/emeu/mecs/mecs2006/excel/Table6_1.xls",
                    :crop => (184..263),
                    :headers => ["NAICS Code", "Subsector and Industry", "Consumption per Employee", "Consumption per Dollar of Value Added", "Consumption per Dollar of Value of Shipments"])

    # U.S. Census Geographic Terms and Definitions
    RemoteTable.new('http://www.census.gov/popest/about/geo/state_geocodes_v2009.txt',
                    :skip => 6,
                    :headers => %w{ Region Division FIPS Name },
                    :select => proc { |row| row['Division'].to_i > 0 and row['FIPS'].to_i == 0 })

    # state census divisions from the U.S. Census
    RemoteTable.new('http://www.census.gov/popest/about/geo/state_geocodes_v2009.txt',
                    :skip => 8,
                    :headers => ['Region', 'Division', 'State FIPS', 'Name'],
                    :select => proc { |row| row['State FIPS'].to_i > 0 })

    # OpenGeoCode.org's Country Codes to Country Names list
    RemoteTable.new('http://opengeocode.org/download/countrynames.txt',
                    :format => :delimited,
                    :delimiter => ';',
                    :headers => false,
                    :skip => 22)

    # heating degree day data from WRI CAIT
    RemoteTable.new('https://docs.google.com/spreadsheet/pub?key=0AoQJbWqPrREqdDN4MkRTSWtWRjdfazhRdWllTkVSMkE&output=csv',
                    :select => Proc.new { |record| record['country'] != 'European Union (27)' },
                    :errata => { :url => RemoteTable.new('https://docs.google.com/spreadsheet/pub?key=0AoQJbWqPrREqdDNSMUtCV0h4cUF4UnBKZlNkczlNbFE&output=csv' })

    # US average grid loss factor derived eGRID 2007 data
    RemoteTable.new('http://www.epa.gov/cleanenergy/documents/egridzips/eGRID2010V1_1_STIE_USGC.xls',
                    :sheet => 'USGC',
                    :skip => 5)

    # eGRID 2010 regions and loss factors
    RemoteTable.new('http://www.epa.gov/cleanenergy/documents/egridzips/eGRID2010V1_1_STIE_USGC.xls',
                    :sheet => 'STIE07',
                    :skip => 4,
                    :select => proc { |row| row['eGRID2010 year 2007 file state sequence number'].to_i.between?(1, 51) })

    # eGRID 2010 subregions and electricity emission factors
    RemoteTable.new('http://www.epa.gov/cleanenergy/documents/egridzips/eGRID2010_Version1-1_xls_only.zip',
                    :filename => 'eGRID2010V1_1_year07_AGGREGATION.xls',
                    :sheet => 'SRL07',
                    :skip => 4,
                    :select => proc { |row| row['SEQSRL07'].to_i.between?(1, 26) })

    # U.S. Census State ANSI Code file
    RemoteTable.new('http://www.census.gov/geo/www/ansi/state.txt',
                    :delimiter => '|',
                    :select => proc { |record| record['STATE'].to_i < 60 })

    # Mapping Hacks zipcode database
    RemoteTable.new('http://mappinghacks.com/data/zipcode.zip',
                    :filename => 'zipcode.csv')

    # zipcode states and eGRID Subregions from the US EPA
    RemoteTable.new('http://www.epa.gov/cleanenergy/documents/egridzips/Power_Profiler_Zipcode_Tool_v3-2.xlsx',
                    :sheet => 'Zip-subregion')

    # horse breeds
    RemoteTable.new('http://www.freebase.com/type/exporttypeinstances/base/horses/horse_breed?page=0&filter_mode=type&filter_view=table&show%01p%3D%2Ftype%2Fobject%2Fname%01index=0&show%01p%3D%2Fcommon%2Ftopic%2Fimage%01index=1&show%01p%3D%2Fcommon%2Ftopic%2Farticle%01index=2&sort%01p%3D%2Ftype%2Fobject%2Ftype%01p%3Dlink%01p%3D%2Ftype%2Flink%2Ftimestamp%01index=false&=&exporttype=csv-8')

    # Brighter Planet's list of cat and dog breeds, genders, and weights
    RemoteTable.new('http://static.brighterplanet.com/science/data/consumables/pets/breed_genders.csv',
                    :encoding => 'ISO-8859-1',
                    :select => proc { |row| row['gender'].present? })

    # residential electricity prices from the EIA
    RemoteTable.new('http://www.eia.doe.gov/cneaf/electricity/page/sales_revenue.xls',
                    :select => proc { |row| row['Year'].to_s.first(4).to_i > 1989 })

    # residential natural gas prices from the EIA
    # for definition of `NaturalGasParser` see https://github.com/brighterplanet/earth/blob/master/lib/earth/residence/residence_fuel_price/data_miner.rb
    RemoteTable.new('http://tonto.eia.doe.gov/dnav/ng/xls/ng_pri_sum_a_EPG0_FWA_DMcf_a.xls',
                    :sheet => 'Data 1',
                    :skip => 2,
                    :select => proc { |row| row['year'].to_i > 1989 },
                    :transform => { :class => NaturalGasParser })

    # 2005 EIA Residential Energy Consumption Survey microdata
    RemoteTable.new('http://www.eia.doe.gov/emeu/recs/recspubuse05/datafiles/RECS05alldata.csv',
                    :headers => :upcase)

    # Public albums from the Facebook Engineering Team
    RemoteTable.new('https://graph.facebook.com/Engineering/albums', format: :json, root_node: 'data')

    # ...and more from the tests...

    RemoteTable.new 'http://spreadsheets.google.com/pub?key=t5HM1KbaRngmTUbntg8JwPA&single=true&gid=0'

    RemoteTable.new 'http://spreadsheets.google.com/pub?key=t5HM1KbaRngmTUbntg8JwPA'

    RemoteTable.new 'http://spreadsheets.google.com/pub?key=t5HM1KbaRngmTUbntg8JwPA', :skip => 1, :headers => false

    RemoteTable.new 'http://spreadsheets.google.com/pub?key=tObVAGyqOkCBtGid0tJUZrw'

    RemoteTable.new 'http://spreadsheets.google.com/pub?key=tObVAGyqOkCBtGid0tJUZrw', :headers => %w{ col1 col2 col3 }

    RemoteTable.new 'http://spreadsheets.google.com/pub?key=tujrgUOwDSLWb-P4KCt1qBg'

    RemoteTable.new 'http://tonto.eia.doe.gov/dnav/pet/xls/PET_PRI_RESID_A_EPPR_PTA_CPGAL_M.xls', :transform => { :class => FuelOilParser }

    RemoteTable.new 'http://www.freebase.com/type/exporttypeinstances/base/horses/horse_breed?page=0&filter_mode=type&filter_view=table&show%01p%3D%2Ftype%2Fobject%2Fname%01index=0&show%01p%3D%2Fcommon%2Ftopic%2Fimage%01index=1&show%01p%3D%2Fcommon%2Ftopic%2Farticle%01index=2&sort%01p%3D%2Ftype%2Fobject%2Ftype%01p%3Dlink%01p%3D%2Ftype%2Flink%2Ftimestamp%01index=false&=&exporttype=csv-8'

    RemoteTable.new 'http://www.fueleconomy.gov/FEG/epadata/02data.zip', :filename => 'guide_jan28.xls'

    RemoteTable.new 'http://www.fueleconomy.gov/FEG/epadata/08data.zip', :filename => '2008_FE_guide_ALL_rel_dates_-no sales-for DOE-5-1-08.csv'

    RemoteTable.new 'http://www.fueleconomy.gov/FEG/epadata/08data.zip', :glob => '/*.csv'

    RemoteTable.new 'http://www.fueleconomy.gov/FEG/epadata/98guide6.zip', :filename => '98guide6.csv'

    RemoteTable.new 'http://www.worldmapper.org/data/opendoc/2_worldmapper_data.ods', :sheet => 'Data', :keep_blank_rows => true

    RemoteTable.new 'https://spreadsheets.google.com/pub?key=t5HM1KbaRngmTUbntg8JwPA'

    RemoteTable.new 'www.customerreferenceprogram.org/uploads/CRP_RFP_template.xlsx'

    RemoteTable.new 'www.customerreferenceprogram.org/uploads/CRP_RFP_template.xlsx', :headers => %w{foo bar baz}

    RemoteTable.new 'www.customerreferenceprogram.org/uploads/CRP_RFP_template.xlsx', :headers => false

    RemoteTable.new 'http://www.transtats.bts.gov/DownLoad_Table.asp?Table_ID=293&Has_Group=3&Is_Zipped=0', :form_data => 'UserTableName=T_100_Segment__All_Carriers&[...]', :compression => :zip, :glob => '/*.csv'

    RemoteTable.new "http://www.faa.gov/air_traffic/publications/atpubs/CNT/5-2-E.htm",
                    :encoding => 'US-ASCII',
                    :row_xpath => '//table/tr[2]/td/table/tr',
                    :column_xpath => 'td'

    RemoteTable.new "http://www.faa.gov/air_traffic/publications/atpubs/CNT/5-2-G.htm",
                    :encoding => 'windows-1252',
                    :row_xpath => '//table/tr[2]/td/table/tr',
                    :column_xpath => 'td',
                    :errata => Errata.new(:url => 'http://spreadsheets.google.com/pub?key=tObVAGyqOkCBtGid0tJUZrw',
                                          :responder => AircraftGuru.new)

    RemoteTable.new "http://www.faa.gov/air_traffic/publications/atpubs/CNT/5-2-G.htm",
                    :encoding => 'windows-1252',
                    :row_xpath => '//table/tr[2]/td/table/tr',
                    :column_xpath => 'td',
                    :errata => { :url => 'http://spreadsheets.google.com/pub?key=tObVAGyqOkCBtGid0tJUZrw',
                                 :responder => AircraftGuru.new }

    RemoteTable.new 'http://www.fueleconomy.gov/FEG/epadata/00data.zip',
                    :filename => 'Gd6-dsc.txt',
                    :format => :fixed_width,
                    :crop => 21..26, # inclusive
                    :cut => '2-',
                    :select => proc { |row| /\A[A-Z]/.match row['code'] },
                    :schema => [[ 'code',   2, { :type => :string }  ],
                                [ 'spacer', 2 ],
                                [ 'name',   52, { :type => :string } ]]

    RemoteTable.new 'http://cloud.github.com/downloads/seamusabshere/remote_table/test2.fixed_width.txt',
                    :format => :fixed_width,
                    :skip => 1,
                    :schema => [[ 'header4', 10, { :type => :string }  ],
                                [ 'spacer',  1 ],
                                [ 'header5', 10, { :type => :string } ],
                                [ 'spacer',  12 ],
                                [ 'header6', 10, { :type => :string } ]]

    RemoteTable.new 'http://cloud.github.com/downloads/seamusabshere/remote_table/test2.fixed_width.txt',
                    :format => :fixed_width,
                    :keep_blank_rows => true,
                    :skip => 1,
                    :schema => [[ 'header4', 10, { :type => :string }  ],
                                [ 'spacer',  1 ],
                                [ 'header5', 10, { :type => :string } ],
                                [ 'spacer',  12 ],
                                [ 'header6', 10, { :type => :string } ]]

    RemoteTable.new 'http://cloud.github.com/downloads/seamusabshere/remote_table/remote_table_row_hash_test.fixed_width.txt',
                    :format => :fixed_width,
                    :skip => 1,
                    :schema => [[ 'header1', 10, { :type => :string }  ],
                                [ 'spacer',  1 ],
                                [ 'header2', 10, { :type => :string } ],
                                [ 'spacer',  12 ],
                                [ 'header3', 10, { :type => :string } ]]

    RemoteTable.new 'http://cloud.github.com/downloads/seamusabshere/remote_table/remote_table_row_hash_test.alternate_order.fixed_width.txt',
                    :format => :fixed_width,
                    :skip => 1,
                    :schema => [[ 'spacer',  11 ],
                                [ 'header2', 10, { :type => :string }  ],
                                [ 'spacer',  1 ],
                                [ 'header3', 10, { :type => :string } ],
                                [ 'spacer',  1 ],
                                [ 'header1', 10, { :type => :string } ]]

## Requirements

* Unix tools like curl, iconv, perl, cat, cut, tail, etc. accessible from your `$PATH`
* geo\_ruby and dbf gems if you plan on fetching shapefiles

## Wishlist

* Win32 compat

## Authors

* Seamus Abshere <seamus@abshere.net>
* Andy Rossmeissl <andy@rossmeissl.net>

## Copyright

Copyright (c) 2012 Brighter Planet. See LICENSE for details.
