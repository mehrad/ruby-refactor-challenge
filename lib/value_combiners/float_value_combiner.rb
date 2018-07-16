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

class FloatValueCombiner
KEYS = [
    'Avg CPC',
    'CTR',
    'Est EPC',
    'newBid',
    'Costs',
    'Avg Pos'
  ]

    def combine(hash)
        KEYS.each do |key|
        hash[key] = hash[key].from_german_to_f.to_german_s
        end
        return hash
    end
end
