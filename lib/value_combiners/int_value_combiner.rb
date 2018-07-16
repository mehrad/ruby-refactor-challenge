class IntValueCombiner
KEYS = [
    'Clicks',
    'Impressions',
    'ACCOUNT - Clicks',
    'CAMPAIGN - Clicks',
    'BRAND - Clicks',
    'BRAND+CATEGORY - Clicks',
    'ADGROUP - Clicks',
    'KEYWORD - Clicks'
  ]

    def combine(hash)
        KEYS.each do |key|
        hash[key] = hash[key].to_s
        end
        return hash
    end
end
