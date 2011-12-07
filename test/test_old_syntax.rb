require 'helper'

$test2_rows_with_blanks = [
  { 'header4' => '', 'header5' => '', 'header6' => '' },
  { 'header4' => '1 at 4', 'header5' => '1 at 5', 'header6' => '1 at 6' },
  { 'header4' => '', 'header5' => '', 'header6' => '' },
  { 'header4' => '2 at 4', 'header5' => '2 at 5', 'header6' => '2 at 6' },
]
$test2_rows = [
  { 'header4' => '1 at 4', 'header5' => '1 at 5', 'header6' => '1 at 6' },
  { 'header4' => '2 at 4', 'header5' => '2 at 5', 'header6' => '2 at 6' },
]
$test2_rows_with_blanks.freeze
$test2_rows.freeze

class TestOldSyntax < Test::Unit::TestCase
  should "open an XLSX like an array (numbered columns)" do
    t = RemoteTable.new(:url => 'www.customerreferenceprogram.org/uploads/CRP_RFP_template.xlsx', :headers => false)
    assert_equal "Software-As-A-Service", t.rows[5][0]
  end

  should "open an XLSX with custom headers" do
    t = RemoteTable.new(:url => 'www.customerreferenceprogram.org/uploads/CRP_RFP_template.xlsx', :headers => %w{foo bar baz})
    assert_equal "Secure encryption of all data", t.rows[5]['foo']
  end

  should "open an XLSX" do
    t = RemoteTable.new(:url => 'www.customerreferenceprogram.org/uploads/CRP_RFP_template.xlsx')
    assert_equal "Secure encryption of all data", t.rows[5]["Requirements"]
  end
  
  should "work on filenames with spaces, using globbing" do
    t = RemoteTable.new :url => 'http://www.fueleconomy.gov/FEG/epadata/08data.zip', :glob => '/*.csv'
    assert_equal 'ASTON MARTIN', t.rows.first['MFR']
  end
  
  should "work on filenames with spaces" do
    t = RemoteTable.new :url => 'http://www.fueleconomy.gov/FEG/epadata/08data.zip', :filename => '2008_FE_guide_ALL_rel_dates_-no sales-for DOE-5-1-08.csv'
    assert_equal 'ASTON MARTIN', t.rows.first['MFR']
  end
  
  should "ignore UTF-8 byte order marks" do
    t = RemoteTable.new :url => 'http://www.freebase.com/type/exporttypeinstances/base/horses/horse_breed?page=0&filter_mode=type&filter_view=table&show%01p%3D%2Ftype%2Fobject%2Fname%01index=0&show%01p%3D%2Fcommon%2Ftopic%2Fimage%01index=1&show%01p%3D%2Fcommon%2Ftopic%2Farticle%01index=2&sort%01p%3D%2Ftype%2Fobject%2Ftype%01p%3Dlink%01p%3D%2Ftype%2Flink%2Ftimestamp%01index=false&=&exporttype=csv-8'
    assert_equal 'Tawleed', t.rows.first['name']
  end
  
  # this will die with an error about libcurl if your curl doesn't support ssl
  should "connect using HTTPS if available" do
    t = RemoteTable.new(:url => 'https://spreadsheets.google.com/pub?key=t5HM1KbaRngmTUbntg8JwPA')
    assert_equal 'Gulf Coast',     t.rows.first['PAD district name']
    assert_equal 'AL',             t.rows.first['State']
    assert_equal 'Rocky Mountain', t.rows.last['PAD district name']
    assert_equal 'WY',             t.rows.last['State']
  end
  
  should "read an HTML table made with frontpage" do
    t = RemoteTable.new :url => "http://www.faa.gov/air_traffic/publications/atpubs/CNT/5-2-E.htm",
                        :encoding => 'US-ASCII',
                        :row_xpath => '//table/tr[2]/td/table/tr',
                        :column_xpath => 'td'
    assert_equal 'E110', t.rows.first['Designator']
    assert_equal 'EMBRAER', t.rows.first['Manufacturer']
    assert_equal 'EZKC', t.rows.last['Designator']
    assert_equal 'EZ King Cobra', t.rows.last['Model']
  end
  
  should "hash rows without paying attention to order" do
    x = ActiveSupport::OrderedHash.new
    x[:a] = 1
    x[:b] = 2
  
    y = ActiveSupport::OrderedHash.new
    y[:b] = 2
    y[:a] = 1
  
    assert_not_equal Marshal.dump(x), Marshal.dump(y)
    assert_equal RemoteTable::Transform.row_hash(x), RemoteTable::Transform.row_hash(y)
  end
  
  should "open a Google Docs url (as a CSV)" do
    t = RemoteTable.new(:url => 'http://spreadsheets.google.com/pub?key=t5HM1KbaRngmTUbntg8JwPA')
    assert_equal 'Gulf Coast',     t.rows.first['PAD district name']
    assert_equal 'AL',             t.rows.first['State']
    assert_equal 'Rocky Mountain', t.rows.last['PAD district name']
    assert_equal 'WY',             t.rows.last['State']
  end
  
  should "open a Google Docs url (as a CSV, with sheet options)" do
    t = RemoteTable.new(:url => 'http://spreadsheets.google.com/pub?key=t5HM1KbaRngmTUbntg8JwPA&single=true&gid=0')
    assert_equal 'Gulf Coast',     t.rows.first['PAD district name']
    assert_equal 'AL',             t.rows.first['State']
    assert_equal 'Rocky Mountain', t.rows.last['PAD district name']
    assert_equal 'WY',             t.rows.last['State']
  end
  
  should "open a Google Docs url as a CSV without headers" do
    t = RemoteTable.new(:url => 'http://spreadsheets.google.com/pub?key=t5HM1KbaRngmTUbntg8JwPA', :skip => 1, :headers => false)
    assert_equal 'AL',             t.rows.first[0]
    assert_equal 'Gulf Coast',     t.rows.first[4]
    assert_equal 'WY',             t.rows.last[0]
    assert_equal 'Rocky Mountain', t.rows.last[4]
  end
  
  should "take the last of values if the header is duplicated" do
    t = RemoteTable.new(:url => 'http://spreadsheets.google.com/pub?key=tujrgUOwDSLWb-P4KCt1qBg')
    assert_equal '2', t.rows.first['dup_header']
  end
  
  should "return an Array when instructed not to use headers" do
    t = RemoteTable.new(:url => 'http://spreadsheets.google.com/pub?key=t5HM1KbaRngmTUbntg8JwPA', :skip => 1, :headers => false)
    t.rows.each do |row|
      assert row.is_a?(::Array)
    end
  end
  
  %w{ csv ods xls }.each do |format|
    should "read #{format}" do
      t = RemoteTable.new(:url => "http://cloud.github.com/downloads/seamusabshere/remote_table/test2.#{format}")
      # no blank headers
      assert t.rows.all? { |row| row.keys.all?(&:present?) }
      # correct values
      t.rows.each_with_index do |row, index|
        assert_equal $test2_rows[index], row.except('row_hash')
      end
    end
  
    should "read #{format}, keeping blank rows" do
      t = RemoteTable.new(:url => "http://cloud.github.com/downloads/seamusabshere/remote_table/test2.#{format}", :keep_blank_rows => true)
      # no blank headers
      assert t.rows.all? { |row| row.keys.all?(&:present?) }
      # correct values
      t.rows.each_with_index do |row, index|
        assert_equal $test2_rows_with_blanks[index], row.except('row_hash')
      end
    end
  end
  
  should "read fixed width correctly" do
    t = RemoteTable.new(:url => 'http://cloud.github.com/downloads/seamusabshere/remote_table/test2.fixed_width.txt',
                        :format => :fixed_width,
                        :skip => 1,
                        :schema => [[ 'header4', 10, { :type => :string }  ],
                                    [ 'spacer',  1 ],
                                    [ 'header5', 10, { :type => :string } ],
                                    [ 'spacer',  12 ],
                                    [ 'header6', 10, { :type => :string } ]])
  
    # no blank headers
    assert t.rows.all? { |row| row.keys.all?(&:present?) }
    # correct values
    t.rows.each_with_index do |row, index|
      assert_equal row.except('row_hash'), $test2_rows[index]
    end
  end
  
  should "read fixed width correctly, keeping blank rows" do
    t = RemoteTable.new(:url => 'http://cloud.github.com/downloads/seamusabshere/remote_table/test2.fixed_width.txt',
                        :format => :fixed_width,
                        :keep_blank_rows => true,
                        :skip => 1,
                        :schema => [[ 'header4', 10, { :type => :string }  ],
                                    [ 'spacer',  1 ],
                                    [ 'header5', 10, { :type => :string } ],
                                    [ 'spacer',  12 ],
                                    [ 'header6', 10, { :type => :string } ]])
  
    # no blank headers
    assert t.rows.all? { |row| row.keys.all?(&:present?) }
    # correct values
    t.rows.each_with_index do |row, index|
      assert_equal row.except('row_hash'), $test2_rows_with_blanks[index]
    end
  end
  
  should "have the same row hash across formats" do
    csv = RemoteTable.new(:url => 'http://cloud.github.com/downloads/seamusabshere/remote_table/remote_table_row_hash_test.csv')
    ods = RemoteTable.new(:url => 'http://cloud.github.com/downloads/seamusabshere/remote_table/remote_table_row_hash_test.ods')
    xls = RemoteTable.new(:url => 'http://cloud.github.com/downloads/seamusabshere/remote_table/remote_table_row_hash_test.xls')
    fixed_width = RemoteTable.new(:url => 'http://cloud.github.com/downloads/seamusabshere/remote_table/remote_table_row_hash_test.fixed_width.txt',
                                  :format => :fixed_width,
                                  :skip => 1,
                                  :schema => [[ 'header1', 10, { :type => :string }  ],
                                              [ 'spacer',  1 ],
                                              [ 'header2', 10, { :type => :string } ],
                                              [ 'spacer',  12 ],
                                              [ 'header3', 10, { :type => :string } ]])
  
    csv2 = RemoteTable.new(:url => 'http://cloud.github.com/downloads/seamusabshere/remote_table/remote_table_row_hash_test.alternate_order.csv')
    ods2 = RemoteTable.new(:url => 'http://cloud.github.com/downloads/seamusabshere/remote_table/remote_table_row_hash_test.alternate_order.ods')
    xls2 = RemoteTable.new(:url => 'http://cloud.github.com/downloads/seamusabshere/remote_table/remote_table_row_hash_test.alternate_order.xls')
    fixed_width2 = RemoteTable.new(:url => 'http://cloud.github.com/downloads/seamusabshere/remote_table/remote_table_row_hash_test.alternate_order.fixed_width.txt',
                                   :format => :fixed_width,
                                   :skip => 1,
                                   :schema => [[ 'spacer',  11 ],
                                               [ 'header2', 10, { :type => :string }  ],
                                               [ 'spacer',  1 ],
                                               [ 'header3', 10, { :type => :string } ],
                                               [ 'spacer',  1 ],
                                               [ 'header1', 10, { :type => :string } ]])
  
  
    reference = csv.rows[0]['row_hash']
  
    # same row hashes
    assert_equal reference, ods.rows[0]['row_hash']
    assert_equal reference, xls.rows[0]['row_hash']
    assert_equal reference, fixed_width.rows[0]['row_hash']
    # same row hashes with different order
    assert_equal reference, csv2.rows[0]['row_hash']
    assert_equal reference, ods2.rows[0]['row_hash']
    assert_equal reference, xls2.rows[0]['row_hash']
    assert_equal reference, fixed_width2.rows[0]['row_hash']
  end
  
  should "open an ODS" do
    t = RemoteTable.new(:url => 'http://www.worldmapper.org/data/opendoc/2_worldmapper_data.ods', :sheet => 'Data', :keep_blank_rows => true)
  
    assert_equal 'Central Africa', t.rows[5]['name']
    assert_equal 99,               t.rows[5]['MAP DATA population (millions) 2002'].to_i
  end
end
