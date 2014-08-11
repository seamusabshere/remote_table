# encoding: utf-8
require 'helper'
require 'tempfile'

describe RemoteTable do
  it "opens a json without root" do
    t = RemoteTable.new "file://#{File.expand_path('../data/data_no_root.json', __FILE__)}"
    t[0]['name'].must_equal 'Seamus Abshere'
    t[0]['city'].must_equal 'Madison'
    t[1]['name'].must_equal 'Derek Kastner'
    t[1]['city'].must_equal 'Lansing'
  end

  it "opens a json with root" do
    t = RemoteTable.new "file://#{File.expand_path('../data/data_with_root.json', __FILE__)}", root_node: 'data'
    t[0]['name'].must_equal 'Seamus Abshere'
    t[0]['city'].must_equal 'Madison'
    t[1]['name'].must_equal 'Derek Kastner'
    t[1]['city'].must_equal 'Lansing'
  end

  it "doesn't screw up UTF-8" do
    t = RemoteTable.new "file://#{File.expand_path('../data/airports.utf8.csv', __FILE__)}"
    t[3]['city'].must_equal "Puerto Inírida"
  end

  it "likes paths as much as urls for local files" do
    by_url = RemoteTable.new "file://#{File.expand_path('../data/airports.utf8.csv', __FILE__)}"
    by_path = RemoteTable.new File.expand_path('../data/airports.utf8.csv', __FILE__)
    by_path.rows.must_equal by_url.rows
  end

  it "strips whitespace from headers" do
    t = RemoteTable.new 'test/data/lots of spaces.csv'
    t[0]['a one'].must_equal 'a1'
    t[0]['b two'].must_equal 'b2'
    t[0]['c three'].must_equal 'c3'
  end

  {
  # IMPOSSIBLE "../data/list-en1-semic-3.office-2011-for-mac-sp1-excel-95.binary.xls" => {:format=>"xls",         :encoding=>"binary"},
  "../data/list-en1-semic-3.office-2011-for-mac-sp1.binary.xlsx"         => {:format=>"xlsx"},
  "../data/list-en1-semic-3.office-2011-for-mac-sp1.binary.xls"          => {:format=>"xls"},
  "../data/list-en1-semic-3.neooffice.binary.ods"                        => {:format=>"ods"},
  "../data/list-en1-semic-3.neooffice.iso-8859-1.fixed_width-64"         => {:format=>"fixed_width", :encoding=>"iso-8859-1", :schema => [['name', 63, { :type => :string }], ['iso_3166', 2, { :type => :string }]]},
  "../data/list-en1-semic-3.neooffice.utf-8.fixed_width-62"              => {:format=>"fixed_width", :schema => [['name', 61, { :type => :string }], ['iso_3166', 2, { :type => :string }]]},
  # TODO "../data/list-en1-semic-3.office-2011-for-mac-sp1.utf-8.html"          => {:format=>"html" },
  # TODO "../data/list-en1-semic-3.office-2011-for-mac-sp1.iso-8859-1.html"     => {:format=>"html", :encoding=>"iso-8859-1"},
  # TODO "../data/list-en1-semic-3.neooffice.utf-8.html"                        => {:format=>"html" },
  "../data/list-en1-semic-3.neooffice.utf-8.xml"                         => {:format=>"xml", :row_css=>'Row', :column_css => 'Data', :select => proc { |row| row[1].to_s =~ /[A-Z]{2}/ }},
  "../data/list-en1-semic-3.neooffice.iso-8859-1.csv"                    => {:format=>"csv", :encoding=>"iso-8859-1", :delimiter => ';'},
  "../data/list-en1-semic-3.original.iso-8859-1.csv"                     => {:format=>"csv", :encoding=>"iso-8859-1", :delimiter => ';'},
  "../data/list-en1-semic-3.office-2011-for-mac-sp1.mac.csv-comma"       => {:format=>"csv", :encoding=>"MACROMAN"}, # comma because no option in excel
  "../data/list-en1-semic-3.neooffice.utf-8.csv"                         => {:format=>"csv", :delimiter => ';'}
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

  it "pass through fastercsv options" do
    f = Tempfile.new 'pass-through-fastercsv-options'
    f.write %{3,Title example,Body example with a <a href="">link</a>,test category}
    f.flush
    t = RemoteTable.new "file://#{f.path}", :quote_char => %{'}, :headers => nil # this should really be "headers => false"
    t[0][2].must_equal %{Body example with a <a href="">link</a>}
    f.close
  end

  it "treats quotes as not special in a pipe-delimited file" do
    t = RemoteTable.new "file://#{File.expand_path('../data/cm.txt', __FILE__)}", :delimiter => '|', :headers => false
    t[0][1].must_equal %{OPEIU LOCAL 153 "VOTE" (VOICE OF THE ELECTORATE) COMMITTEE}
  end

  it "treats quotes as not special in a tab-delimited file" do
    t = RemoteTable.new "file://#{File.expand_path('../data/cm.tsv', __FILE__)}", :delimiter => "\t", :headers => false
    t[0][1].must_equal %{OPEIU LOCAL 153 "VOTE" (VOICE OF THE ELECTORATE) COMMITTEE}
  end

  # using backticks
  it "allows quoted pipes in a pipe-delimited file" do
    t = RemoteTable.new "file://#{File.expand_path('../data/cm.pathological.txt', __FILE__)}", :delimiter => '|', :headers => false, :quote_char => '`'
    t[0][1].must_equal %{OPEIU LOCAL 153 '"|VOTE|"' (VOICE OF THE ELECTORATE) COMMITTEE}
  end

  it "open a yaml" do
    t = RemoteTable.new "file://#{File.expand_path('../data/data.yml', __FILE__)}"
    t[0]['name'].must_equal 'Seamus Abshere'
    t[0]['city'].must_equal 'Madison'
    t[1]['name'].must_equal 'Derek Kastner'
    t[1]['city'].must_equal 'Lansing'
  end

  it "reads html with xpath" do
    t = RemoteTable.new 'test/data/table.html', row_xpath: '//tr', column_xpath: 'td'
    t[0]['h1'].must_equal 'a'
    t[1]['h3'].must_equal 'f'
  end

  # fixes ArgumentError: invalid byte sequence in UTF-8
  it %{safely strip soft hyphens and read windows-1252 html} do
    row_xpath = '/html/body/table[2]/tr/td/center/table/tr[3]/td/table/tr'
    t = RemoteTable.new 'test/data/faa-aircraft.html.bz2', :row_xpath => row_xpath, :column_xpath => 'td', :encoding => 'windows-1252', format: :html
    t.rows.detect { |row| row['Model'] == 'A300B4600' }.wont_equal nil
  end

  {
    'foo.ods' => :ods,
    'foo.open_office' => :ods,
    'foo.xlsx' => :xlsx,
    'foo.excelx' => :xlsx,
    'foo.xls' => :xls,
    'foo.excel' => :xls,
    'foo.csv' => :delimited,
    'foo.tsv' => :delimited,
    'foo.delimited' => :delimited,
    'foo.fixed_width' => :fixed_width,
    'foo.htm' => :html,
    'foo.html' => :html,
    'foo.xml' => :xml,
    'foo.yaml' => :yaml,
    'foo.yml' => :yaml,
    'foo.json' => :json
  }.each do |basename, format|
    it "detects the #{format} format from the filename #{basename}" do
      RemoteTable.guess_format(basename).must_equal format
    end
  end

  it "detects the correct extension name without confusion from basename" do
    [ 'foo.xls', 'xlsx.xls', 'foo_xls' ].each do |basename|
      RemoteTable.guess_format(basename).must_equal :xls
    end
  end
end
