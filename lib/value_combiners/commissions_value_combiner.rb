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

class CommissionsValueCombiner
KEYS = [
    'Commission Value',
    'ACCOUNT - Commission Value',
    'CAMPAIGN - Commission Value',
    'BRAND - Commission Value',
    'BRAND+CATEGORY - Commission Value',
    'ADGROUP - Commission Value',
    'KEYWORD - Commission Value'
  ]

    def combine(hash)
        KEYS.each do |key|
        hash[key] = (@cancellation_factor * @saleamount_factor * hash[key][0].from_german_to_f).to_german_s
        end
        return hash
    end
end
