module JoinEquipmentResultHelpers
  def joined
    result16s = ResultsParser2016.loadhash_by_county_city
    equipments = EquipmentParser.loadhash_by_county_city
    alt_equipments = fixes_for_missing equipments
    result16s.each_pair.map do |key, result_obj|
      ret = result_obj.dup
      ret[:equipment] = equipments[key] || alt_equipments[key]
      ret
    end
  end

  def fixes_for_missing(source_hash)
    Hash[
      Errata.join_fixes.each do |result_key, equipment_key|
        [result_key, source_hash[equipment_key]]
      end
    ]
  end

  def join_fails
    joined.select { |obj| obj[:equipment].nil? }
  end

  def join_fails_sorted
    join_fails.map { |x| [x[:returns][0], x[:county], x[:city]] }.sort
  end
end

class JoinEquipmentResults
  extend JoinEquipmentResultHelpers
end
