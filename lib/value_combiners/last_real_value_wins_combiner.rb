class LastRealValueWinsCombiner

KEYS = [
    'Last Avg CPC',
    'Last Avg Pos'
  ]

    def combine(hash)
        KEYS.each do |key|
        hash[key] = hash[key].select {|v| not (v.nil? or v == 0 or v == '0' or v == '')}.last
        end
        return hash
    end
end
