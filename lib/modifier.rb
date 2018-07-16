class String
  def from_german_to_f
    self.gsub(',', '.').to_f
  end
end

class Float
  def to_german_s
    self.to_s.gsub('.', ',')
  end
end

class Modifier

  KEYWORD_UNIQUE_ID = 'Keyword Unique ID'

  LAST_VALUE_WINS = [
    'Account ID',
    'Account Name',
    'Campaign',
    'Ad Group',
    'Keyword',
    'Keyword Type',
    'Subid',
    'Paused',
    'Max CPC',
    'Keyword Unique ID',
    'ACCOUNT',
    'CAMPAIGN',
    'BRAND',
    'BRAND+CATEGORY',
    'ADGROUP',
    'KEYWORD'
  ]

  LAST_REAL_VALUE_WINS = [
    'Last Avg CPC',
    'Last Avg Pos'
  ]

  INT_VALUES = [
    'Clicks',
    'Impressions',
    'ACCOUNT - Clicks',
    'CAMPAIGN - Clicks',
    'BRAND - Clicks',
    'BRAND+CATEGORY - Clicks',
    'ADGROUP - Clicks',
    'KEYWORD - Clicks'
  ]

  FLOAT_VALUES = [
    'Avg CPC',
    'CTR',
    'Est EPC',
    'newBid',
    'Costs',
    'Avg Pos'
  ]

  COMMISSIONS_VALUES = [
    'Commission Value',
    'ACCOUNT - Commission Value',
    'CAMPAIGN - Commission Value',
    'BRAND - Commission Value',
    'BRAND+CATEGORY - Commission Value',
    'ADGROUP - Commission Value',
    'KEYWORD - Commission Value'
  ]

  NUMBER_OF_COMMISSIONS_VALUE = 'number of commissions'

  LINES_PER_FILE = 120000

  DEFAULT_READ_CSV_OPTIONS = { :col_sep => "\t", :headers => :first_row }
  DEFAUL_WRITE_CSV_OPTIONS = { :col_sep => "\t", :headers => :first_row, :row_sep => "\r\n" }

  def initialize(saleamount_factor, cancellation_factor)
    @saleamount_factor = saleamount_factor
    @cancellation_factor = cancellation_factor
  end

  def modify(latest_file)

    latest_file_enumerator = generate_file_enumerator(latest_file)

    combiner = Combiner.new do |value|
      value[KEYWORD_UNIQUE_ID]
    end.combine(latest_file_enumerator)

    merger = Enumerator.new do |yielder|
      while true
        begin
          list_of_rows = combiner.next
          merged = combine_hashes(list_of_rows)
          yielder.yield(combine_values(merged))
        rescue StopIteration
          break
        end
      end
    end

    done = false
    file_index = 0
    file_name = latest_file.gsub('.txt', '')
    until done do
      CSV.open(file_name + "_#{file_index}.txt", "wb", DEFAUL_WRITE_CSV_OPTIONS ) do |csv|
        merged = merger.next
        csv << merged.keys
        line_count = 1
        while line_count < LINES_PER_FILE
          begin
            merged = merger.next
            csv << merged
            line_count +=1
          rescue StopIteration
            done = true
            break
          end
        end
        file_index += 1
      end
    end
  end

  private

  def generate_file_enumerator(latest_file)
    file_name = "#{file}.sorted"
    content_as_table = parse(latest_file)

    sorted_content = get_sorted_content(content_as_table,'Clicks')

    write(sorted_content, content_as_table.headers, file_name)

    return lazy_read(file_name)
  end

  def combine(merged)
    result = []
    merged.each do |_, hash|
      result << combine_values(hash)
    end
    result
  end

  def combine_values(hash)
    LAST_VALUE_WINS.each do |key|
      hash[key] = hash[key].last
    end
    LAST_REAL_VALUE_WINS.each do |key|
      hash[key] = hash[key].select {|v| not (v.nil? or v == 0 or v == '0' or v == '')}.last
    end
    INT_VALUES.each do |key|
      hash[key] = hash[key][0].to_s
    end
    FLOAT_VALUES.each do |key|
      hash[key] = hash[key][0].from_german_to_f.to_german_s
    end

    hash[NUMBER_OF_COMMISSIONS_VALUE] = (
                  @cancellation_factor * hash[NUMBER_OF_COMMISSIONS_VALUE][0].from_german_to_f
                ).to_german_s

    COMMISSIONS_VALUES.each do |key|
      hash[key] = (@cancellation_factor * @saleamount_factor * hash[key][0].from_german_to_f).to_german_s
    end
    hash
  end

  def combine_hashes(list_of_rows)
    keys = []
    list_of_rows.each do |row|
      next if row.nil?
      row.headers.each do |key|
        keys << key
      end
    end
    result = {}
    keys.each do |key|
      result[key] = []
      list_of_rows.each do |row|
        result[key] << (row.nil? ? nil : row[key])
      end
    end
    result
  end

  def parse(file)
    CSV.read(file, DEFAULT_READ_CSV_OPTIONS)
  end

  def lazy_read(file)
    Enumerator.new do |yielder|
      CSV.foreach(file, DEFAULT_READ_CSV_OPTIONS) do |row|
        yielder.yield(row)
      end
    end
  end

  def write(content, headers, output)
    CSV.open(output, "wb", DEFAUL_WRITE_CSV_OPTIONS) do |csv|
      csv << headers
      content.each do |row|
        csv << row
      end
    end
  end

  public
  def get_sorted_content(content_as_table, key)
    index_of_key = content_as_table.headers.index(key)
    return content_as_table.sort_by { |a| -a[index_of_key].to_i }
  end
end
