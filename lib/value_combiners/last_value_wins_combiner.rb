class LastValueWinsCombiner
KEYS = [
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

    def combine(hash)
        KEYS.each do |key|
        hash[key] = hash[key].last
        end
        return hash
    end
end
