require File.expand_path('lib/combiner',File.dirname(__FILE__))
require File.expand_path('lib/modifier',File.dirname(__FILE__))
require 'csv'
require 'date'

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

def get_latest_by_date(name)
  files = Dir["#{ ENV["HOME"] }/workspace/*#{name}*.txt"]

  files.sort_by! do |file|
    file_name = /\d+-\d+-\d+_[[:alpha:]]+\.txt$/.match file
    file_date = file_name.to_s.match /\d+-\d+-\d+/

    date = DateTime.parse(file_date.to_s)
  end

  throw RuntimeError if files.empty?

  files.last
end

modified = input = get_latest_by_date('project_2012-07-27_2012-10-10_performancedata')
modification_factor = 1
cancellaction_factor = 0.4
modifier = Modifier.new(modification_factor, cancellaction_factor)
modifier.modify(modified, input)

puts "DONE modifying"
