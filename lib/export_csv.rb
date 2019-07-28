class ExportCsv
  
  class << self
    def joined_shallow_data
      JoinEquipmentResults.join_2012_to_2016
        .map do |key, obj|
          Hash[
            obj
            .slice(:county_city_key)
            .merge!(obj[:party_counts])
            .merge!(obj[:prev][:party_counts])
            .map { |k, v| [k.to_sym, v] }
          ]
        end
    end

    def dump_to(filename)
      CSV.open(filename, "w+") do |csv|
        all_rows = joined_shallow_data
        csv << all_rows.first.keys
        all_rows.each { |row| csv << row.values }
      end
    end
  end
end
            
