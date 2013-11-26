require 'helper'

$test2_rows_with_blanks = [
  { 'header4' => '', 'header5' => '', 'header6' => '' },
  { 'header4' => '1 at 4', 'header5' => '1 at 5', 'header6' => '1 at 6' },
  { 'header4' => '', 'header5' => '', 'header6' => '' },
  { 'header4' => '2 at 4', 'header5' => '2 at 5', 'header6' => '2 at 6' },
].map { |hsh| hsh.merge('untitled_1' => '') }
$test2_rows = [
  { 'header4' => '1 at 4', 'header5' => '1 at 5', 'header6' => '1 at 6' },
  { 'header4' => '2 at 4', 'header5' => '2 at 5', 'header6' => '2 at 6' },
].map { |hsh| hsh.merge('untitled_1' => '') }
$test2_rows_with_blanks.freeze
$test2_rows.freeze

describe RemoteTable do
  describe "when using old-style syntax" do
    it "open an XLSX like an array (numbered columns)" do
      t = RemoteTable.new(:url => 'www.customerreferenceprogram.org/uploads/CRP_RFP_template.xlsx', :headers => false)
      t.rows[0][0].must_equal "Requirements"
      t.rows[5][0].must_equal "Software-As-A-Service"
    end

    it "open an XLSX with custom headers" do
      t = RemoteTable.new(:url => 'www.customerreferenceprogram.org/uploads/CRP_RFP_template.xlsx', :headers => %w{foo bar baz})
      t.rows[0]['foo'].must_equal "Requirements"
      t.rows[5]['foo'].must_equal "Software-As-A-Service"
    end

    it "open an XLSX" do
      t = RemoteTable.new(:url => 'www.customerreferenceprogram.org/uploads/CRP_RFP_template.xlsx')
      t.rows[5]["Requirements"].must_equal "Secure encryption of all data"
    end
    
    it "work on filenames with spaces, using globbing" do
      t = RemoteTable.new :url => 'http://www.fueleconomy.gov/FEG/epadata/08data.zip', :glob => '/*.csv'
      t.rows.first['MFR'].must_equal 'ASTON MARTIN'
    end
    
    it "work on filenames with spaces" do
      t = RemoteTable.new :url => 'http://www.fueleconomy.gov/FEG/epadata/08data.zip', :filename => '2008_FE_guide_ALL_rel_dates_-no sales-for DOE-5-1-08.csv'
      t.rows.first['MFR'].must_equal 'ASTON MARTIN'
    end
    
    it "ignore UTF-8 byte order marks" do
      t = RemoteTable.new :url => 'http://www.freebase.com/type/exporttypeinstances/base/horses/horse_breed?page=0&filter_mode=type&filter_view=table&show%01p%3D%2Ftype%2Fobject%2Fname%01index=0&show%01p%3D%2Fcommon%2Ftopic%2Fimage%01index=1&show%01p%3D%2Fcommon%2Ftopic%2Farticle%01index=2&sort%01p%3D%2Ftype%2Fobject%2Ftype%01p%3Dlink%01p%3D%2Ftype%2Flink%2Ftimestamp%01index=false&=&exporttype=csv-8'
      t.rows.first['Name'].must_equal 'Tawleed'
    end
    
    # this will die with an error about libcurl if your curl doesn't support ssl
    it "connect using HTTPS if available" do
      t = RemoteTable.new(:url => 'https://spreadsheets.google.com/pub?key=t5HM1KbaRngmTUbntg8JwPA')
      t.rows.first['PAD district name'].must_equal 'Gulf Coast'
      t.rows.first['State'].must_equal 'AL'
      t.rows.last['PAD district name'].must_equal 'Rocky Mountain'
      t.rows.last['State'].must_equal 'WY'
    end
    
    it "read an HTML table made with frontpage" do
      t = RemoteTable.new :url => "http://www.faa.gov/air_traffic/publications/atpubs/CNT/5-2-E.htm",
                          :encoding => 'US-ASCII',
                          :row_xpath => '//table[2]//table[1]//tr[3]//tr',
                          :column_xpath => 'td'
      t.rows.first['Designator'].must_equal 'E110'
      t.rows.first['Manufacturer'].must_equal 'EMBRAER'
      t.rows.last['Designator'].must_equal 'EZKC'
      t.rows.last['Model'].must_equal 'EZ King Cobra'
    end
    
    it "open a Google Docs url (as a CSV)" do
      t = RemoteTable.new(:url => 'http://spreadsheets.google.com/pub?key=t5HM1KbaRngmTUbntg8JwPA')
      t.rows.first['PAD district name'].must_equal 'Gulf Coast'
      t.rows.first['State'].must_equal 'AL'
      t.rows.last['PAD district name'].must_equal 'Rocky Mountain'
      t.rows.last['State'].must_equal 'WY'
    end
    
    it "open a Google Docs url (as a CSV, with sheet options)" do
      t = RemoteTable.new(:url => 'http://spreadsheets.google.com/pub?key=t5HM1KbaRngmTUbntg8JwPA&single=true&gid=0')
      t.rows.first['PAD district name'].must_equal 'Gulf Coast'
      t.rows.first['State'].must_equal 'AL'
      t.rows.last['PAD district name'].must_equal 'Rocky Mountain'
      t.rows.last['State'].must_equal 'WY'
    end
    
    it "open a Google Docs url as a CSV without headers" do
      t = RemoteTable.new(:url => 'http://spreadsheets.google.com/pub?key=t5HM1KbaRngmTUbntg8JwPA', :skip => 1, :headers => false)
      t.rows.first[0].must_equal 'AL'
      t.rows.first[4].must_equal 'Gulf Coast'
      t.rows.last[0].must_equal 'WY'
      t.rows.last[4].must_equal 'Rocky Mountain'
    end
    
    it "take the last of values if the header is duplicated" do
      t = RemoteTable.new(:url => 'http://spreadsheets.google.com/pub?key=tujrgUOwDSLWb-P4KCt1qBg')
      t.rows.first['dup_header'].must_equal '2'
    end
    
    it "return an Array when instructed not to use headers" do
      t = RemoteTable.new(:url => 'http://spreadsheets.google.com/pub?key=t5HM1KbaRngmTUbntg8JwPA', :skip => 1, :headers => false)
      t.rows.each do |row|
        row.must_be_kind_of ::Array
      end
    end
    
    %w{ csv ods xls }.each do |format|
      it "read #{format}" do
        t = RemoteTable.new(:url => "http://cloud.github.com/downloads/seamusabshere/remote_table/test2.#{format}")
        # no blank headers
        t.rows.all? { |row| row.keys.all?(&:present?) }.must_equal true
        # correct values
        t.rows.each_with_index do |row, index|
          row.except('row_hash').must_equal $test2_rows[index]
        end
      end
    
      it "read #{format}, keeping blank rows" do
        t = RemoteTable.new(:url => "http://cloud.github.com/downloads/seamusabshere/remote_table/test2.#{format}", :keep_blank_rows => true)
        # no blank headers
        t.rows.all? { |row| row.keys.all?(&:present?) }.must_equal true
        # correct values
        t.rows.each_with_index do |row, index|
          row.except('row_hash').must_equal $test2_rows_with_blanks[index]
        end
      end
    end
    
    it "read fixed width correctly" do
      t = RemoteTable.new(:url => 'http://cloud.github.com/downloads/seamusabshere/remote_table/test2.fixed_width.txt',
                          :format => :fixed_width,
                          :skip => 1,
                          :schema => [[ 'header4', 10, { :type => :string }  ],
                                      [ 'spacer',  1 ],
                                      [ 'header5', 10, { :type => :string } ],
                                      [ 'spacer',  12 ],
                                      [ 'header6', 10, { :type => :string } ]])
    
      # no blank headers
      t.rows.all? { |row| row.keys.all?(&:present?) }.must_equal true
      # correct values
      t.rows.each_with_index do |row, index|
        $test2_rows[index].except('untitled_1').must_equal row.except('row_hash')
      end
    end
    
    it "read fixed width correctly, keeping blank rows" do
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
      t.rows.all? { |row| row.keys.all?(&:present?) }.must_equal true
      # correct values
      t.rows.each_with_index do |row, index|
        $test2_rows_with_blanks[index].except('untitled_1').must_equal row.except('row_hash')
      end
    end
    
    it "have the same row hash across formats" do
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
      ods.rows[0]['row_hash'].must_equal reference
      xls.rows[0]['row_hash'].must_equal reference
      fixed_width.rows[0]['row_hash'].must_equal reference
      # same row hashes with different order
      csv2.rows[0]['row_hash'].must_equal reference
      ods2.rows[0]['row_hash'].must_equal reference
      xls2.rows[0]['row_hash'].must_equal reference
      fixed_width2.rows[0]['row_hash'].must_equal reference
    end
    
    it "open an ODS" do
      t = RemoteTable.new(:url => 'http://www.worldmapper.org/data/opendoc/2_worldmapper_data.ods', :sheet => 'Data', :keep_blank_rows => true)
    
      t.rows[5]['name'].must_equal 'Central Africa'
      t.rows[5]['MAP DATA population (millions) 2002'].to_i.must_equal 99
    end
  end
end
