require 'helper'

describe RemoteTable do
  describe ":parser option" do
    it "takes a parser object that responds to #parse(row) and returns an array of rows" do
      class GradeRangeParser
        def parse(row)
          row['range'].split('-').map do |subrange|
            virtual_row = row.dup
            virtual_row.delete 'range'
            virtual_row['grade'] = subrange
            virtual_row
          end
        end
      end
      t = RemoteTable.new "file://#{File.expand_path('../data/ranges.csv', __FILE__)}", parser: GradeRangeParser.new
      t[0].must_equal 'description' => 'great', 'grade' => 'A'
      t[1].must_equal 'description' => 'great', 'grade' => 'B'
      t[2].must_equal 'description' => 'ok', 'grade' => 'C'
      t[3].must_equal 'description' => 'bad', 'grade' => 'D'
      t[4].must_equal 'description' => 'bad', 'grade' => 'F'
    end
  end
end
