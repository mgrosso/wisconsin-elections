module JoinEquipmentResultHelpers
  def joined
    result16s = ResultsParser2016.loadhash_by_county_city
    equipments = EquipmentParser.loadhash_by_county_city
    alt_equipments = EquipmentParser.fixup_join_keys equipments
    result16s.each_pair.map do |key, result_obj|
      ret = result_obj.dup
      ret[:equipment] = equipments[key] || alt_equipments[key]
      ret
    end
  end

  def join_fails
    joined.select { |obj| obj[:equipment].nil? }
  end

  def join_fails_sorted
    join_fails.map { |obj| [obj[:raw][2], obj] }.sort.map { |_, obj| obj }
  end
end

class JoinEquipmentResults
  extend JoinEquipmentResultHelpers
end
