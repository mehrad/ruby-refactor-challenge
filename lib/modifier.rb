require File.expand_path('value_combiners/last_value_wins_combiner',File.dirname(__FILE__))
require File.expand_path('value_combiners/last_real_value_wins_combiner',File.dirname(__FILE__))
require File.expand_path('value_combiners/int_value_combiner',File.dirname(__FILE__))
require File.expand_path('value_combiners/float_value_combiner',File.dirname(__FILE__))
require File.expand_path('value_combiners/commissions_value_combiner',File.dirname(__FILE__))


class Modifier

  KEYWORD_UNIQUE_ID = 'Keyword Unique ID'

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

    write_results(latest_file.gsub('.txt', ''))

  end

  private

  def write_results(file_name)
    done = false
    file_index = 0
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

    hash = LastValueWinsCombiner.combine(hash)

    hash = LastRealValueWinsCombiner.combine(hash)

    hash = IntValueCombiner.combine(hash)

    hash = FloatValueCombiner.combine(hash)

    hash[NUMBER_OF_COMMISSIONS_VALUE] = (
                  @cancellation_factor * hash[NUMBER_OF_COMMISSIONS_VALUE][0].from_german_to_f
                ).to_german_s

    hash = CommissionsValueCombiner.combine(hash)

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
