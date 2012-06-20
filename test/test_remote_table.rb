# encoding: utf-8
require 'helper'
require 'tempfile'

describe RemoteTable do
  it "open an XLSX" do
    t = RemoteTable.new 'http://www.customerreferenceprogram.org/uploads/CRP_RFP_template.xlsx'
    t[5]["Requirements"].must_equal "Secure encryption of all data"
  end

  it "doesn't screw up UTF-8" do
    t = RemoteTable.new "file://#{File.expand_path('../support/airports.utf8.csv', __FILE__)}"
    t[3]['city'].must_equal "Puerto Inírida"
  end

  it "likes paths as much as urls for local files" do
    by_url = RemoteTable.new "file://#{File.expand_path('../support/airports.utf8.csv', __FILE__)}"
    by_path = RemoteTable.new File.expand_path('../support/airports.utf8.csv', __FILE__)
    by_path.rows.must_equal by_url.rows
  end

  it "does its best to download urls without http://" do
    t = RemoteTable.new 'www.customerreferenceprogram.org/uploads/CRP_RFP_template.xlsx'
    t[5]["Requirements"].must_equal "Secure encryption of all data"
  end

  it "add a row hash to every row" do
    t = RemoteTable.new(:url => 'http://www.customerreferenceprogram.org/uploads/CRP_RFP_template.xlsx')
    t[5].row_hash.must_equal "06d8a738551c17735e2731e25c8d0461"
  end

  it "open a google doc" do
    t = RemoteTable.new 'http://spreadsheets.google.com/pub?key=tObVAGyqOkCBtGid0tJUZrw'
    t[0]['name'].must_equal 'Seamus Abshere'
  end

  it "open a csv with custom headers" do
    t = RemoteTable.new 'http://spreadsheets.google.com/pub?key=tObVAGyqOkCBtGid0tJUZrw', :headers => %w{ col1 col2 col3 }
    t[0]['col2'].must_equal 'name'
    t[1]['col2'].must_equal 'Seamus Abshere'
  end

  it "open a yaml" do
    t = RemoteTable.new "file://#{File.expand_path('../fixtures/data.yml', __FILE__)}"
    t[0]['name'].must_equal 'Seamus Abshere'
    t[0]['city'].must_equal 'Madison'
    t[1]['name'].must_equal 'Derek Kastner'
    t[1]['city'].must_equal 'Lansing'
  end

  it "return an ordered hash" do
    t = RemoteTable.new 'http://spreadsheets.google.com/pub?key=tObVAGyqOkCBtGid0tJUZrw'
    t[0].class.must_equal ::ActiveSupport::OrderedHash
  end

  it "pass through fastercsv options" do
    f = Tempfile.new 'pass-through-fastercsv-options'
    f.write %{3,Title example,Body example with a <a href="">link</a>,test category}
    f.flush
    t = RemoteTable.new "file://#{f.path}", :quote_char => %{'}, :headers => nil # this should really be "headers => false"
    t[0][2].must_equal %{Body example with a <a href="">link</a>}
    f.close
  end

  it "open a csv inside a zip file" do
    t = RemoteTable.new  'http://www.epa.gov/climatechange/emissions/downloads10/2010-Inventory-Annex-Tables.zip',
                         :filename => 'Annex Tables/Annex 3/Table A-93.csv',
                         :skip => 1,
                         :select => proc { |row| row['Vehicle Age'].strip =~ /^\d+$/ }
    t[0]['LDGV'].must_equal '9.09%'
  end

  it 'not blow up if each is called twice' do
    t = RemoteTable.new 'http://spreadsheets.google.com/pub?key=tObVAGyqOkCBtGid0tJUZrw'
    count = 0
    t.each { |row| count += 1 }
    first_run = count
    t.each { |row| count += 1}
    count.must_equal first_run*2
  end

  it 'allow itself to be cleared for save memory' do
    t = RemoteTable.new 'http://spreadsheets.google.com/pub?key=tObVAGyqOkCBtGid0tJUZrw'
    t.to_a
    t.send(:cache).length.must_be :>, 0
    t.free
    t.send(:cache).length.must_equal 0
  end

  # fixes ArgumentError: invalid byte sequence in UTF-8
  it %{safely strip soft hyphens and read windows-1252 html} do
    t = RemoteTable.new :url => "http://www.faa.gov/air_traffic/publications/atpubs/CNT/5-2-A.htm", :row_xpath => '//table[2]//table[1]//tr[3]//tr', :column_xpath => 'td', :encoding => 'windows-1252'
    t.rows.detect { |row| row['Model'] == 'A300B4600' }.wont_equal nil
  end

  it %{transliterate characters from ISO-8859-1} do
    t = RemoteTable.new :url => 'http://static.brighterplanet.com/science/data/consumables/pets/breed_genders.csv', :encoding => 'ISO-8859-1'
    t.rows.detect { |row| row['name'] == 'Briquet Griffon Vendéen' }.wont_equal nil
  end

  it %{read xml with css selectors} do
    t = RemoteTable.new 'http://www.nanonull.com/TimeService/TimeService.asmx/getCityTime?city=Chicago', :format => :xml, :row_css => 'string', :headers => false
    /(AM|PM)/.match(t[0][0]).wont_equal nil
  end

  it %{optionally stream rows instead of caching them} do
    t = RemoteTable.new 'http://www.earthtools.org/timezone/40.71417/-74.00639', :format => :xml, :row_xpath => '//timezone/isotime', :headers => false, :streaming => true
    time1 = t[0][0]
    /\d\d\d\d-\d\d-\d\d/.match(time1).wont_equal nil
    sleep 1
    time2 = t[0][0]
    time1.wont_equal time2
  end

  {
  # IMPOSSIBLE "../support/list-en1-semic-3.office-2011-for-mac-sp1-excel-95.binary.xls" => {:format=>"xls",         :encoding=>"binary"},
  "../support/list-en1-semic-3.office-2011-for-mac-sp1.binary.xlsx"         => {:format=>"xlsx"},
  "../support/list-en1-semic-3.office-2011-for-mac-sp1.binary.xls"          => {:format=>"xls"},
  "../support/list-en1-semic-3.neooffice.binary.ods"                        => {:format=>"ods"},
  "../support/list-en1-semic-3.neooffice.iso-8859-1.fixed_width-64"         => {:format=>"fixed_width", :encoding=>"iso-8859-1", :schema => [['name', 63, { :type => :string }], ['iso_3166', 2, { :type => :string }]]},
  "../support/list-en1-semic-3.neooffice.utf-8.fixed_width-62"              => {:format=>"fixed_width", :schema => [['name', 61, { :type => :string }], ['iso_3166', 2, { :type => :string }]]},
  # TODO "../support/list-en1-semic-3.office-2011-for-mac-sp1.utf-8.html"          => {:format=>"html" },
  # TODO "../support/list-en1-semic-3.office-2011-for-mac-sp1.iso-8859-1.html"     => {:format=>"html", :encoding=>"iso-8859-1"},
  # TODO "../support/list-en1-semic-3.neooffice.utf-8.html"                        => {:format=>"html" },
  "../support/list-en1-semic-3.neooffice.utf-8.xml"                         => {:format=>"xml", :row_css=>'Row', :column_css => 'Data', :select => proc { |row| row[1].to_s =~ /[A-Z]{2}/ }},
  "../support/list-en1-semic-3.neooffice.iso-8859-1.csv"                    => {:format=>"csv", :encoding=>"iso-8859-1", :delimiter => ';'},
  "../support/list-en1-semic-3.original.iso-8859-1.csv"                     => {:format=>"csv", :encoding=>"iso-8859-1", :delimiter => ';'},
  "../support/list-en1-semic-3.office-2011-for-mac-sp1.mac.csv-comma"       => {:format=>"csv", :encoding=>"MACROMAN"}, # comma because no option in excel
  "../support/list-en1-semic-3.neooffice.utf-8.csv"                         => {:format=>"csv", :delimiter => ';'}
  }.each do |k, v|
    it %{open #{k} with encoding #{v[:encoding] || 'default'}} do
      options = v.merge(:headers => false, :skip => 2)
      t = RemoteTable.new "file://#{File.expand_path(k, __FILE__)}", options
      a = %{ÅLAND ISLANDS}
      b = (t[1].is_a?(::Array) ? t[1][0] : t[1]['name'])
      if RUBY_VERSION >= '1.9'
        a.encoding.to_s.must_equal 'UTF-8'
        b.encoding.to_s.must_equal 'UTF-8'
      end
      b.must_equal a
    end
  end

  it %{recode as UTF-8 even ISO-8859-1 (or any other encoding)} do
    t = RemoteTable.new 'http://www.iso.org/iso/list-en1-semic-3.txt', :skip => 2, :headers => false, :delimiter => ';', :encoding => 'ISO-8859-1'
    t[1][0].must_equal %{ÅLAND ISLANDS}
  end

  it %{parse a big CSV that is not UTF-8} do
    t = RemoteTable.new 'https://openflights.svn.sourceforge.net/svnroot/openflights/openflights/data/airports.dat', :headers => false#, :encoding => 'UTF-8'
    t[0][1].must_equal 'Goroka'
  end

  it "read only certain rows of an XLSX" do
    t = RemoteTable.new 'www.customerreferenceprogram.org/uploads/CRP_RFP_template.xlsx', :crop => 11..16, :headers => false
    t[0][0].must_equal "Permissioning and access groups for all content"
    t[4][0].must_equal "Manage Multiple Incentive Programs for Participants"

    t = RemoteTable.new 'www.customerreferenceprogram.org/uploads/CRP_RFP_template.xlsx', :crop => 11..16, :headers => %w{ col1 }
    t[0]['col1'].must_equal "Permissioning and access groups for all content"
    t[4]['col1'].must_equal "Manage Multiple Incentive Programs for Participants"
  end

  it "doesn't get confused by :format => nil" do
    t = RemoteTable.new :url => 'http://www.fueleconomy.gov/FEG/epadata/00data.zip', :filename => 'G6080900.xls', :format => nil
    t[0]['Class'].must_equal 'TWO SEATERS'
  end
end
