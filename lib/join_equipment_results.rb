module JoinEquipmentResultHelpers

  def find_missing_equipment(source_hash)
    Hash[
      Errata.equipment_join_fixes.each do |result_key, equipment_key|
        [result_key, source_hash[equipment_key]]
      end
    ]
  end

  def join_equipment(results)
    equipments = EquipmentParser.loadhash_by_county_city
    alt_equipments = find_missing_equipment equipments
    results.each_pair.map do |key, result_obj|
      ret = result_obj.dup
      ret[:equipment] = equipments[key] || alt_equipments[key]
      ret
    end
  end

  def join_2012_to_2016
    hr16 = Hash[equipment_join_2016.map { |x| [x[:county_city_key], x] }]
    hr12 = Hash[equipment_join_2012.map { |x| [x[:county_city_key], x] }]
    fix_keys = Hash[Errata.from_2016_to_2012]
    rjoined = hr16
      .reject { |key, obj| obj[:returns][0] == 0 }
      .map do |key, obj|
        ret = obj.dup
        ret[:prev] = (hr12[key] || hr12[fix_keys[key]]) rescue binding.pry
        [key, ret]
    end
    Hash[rjoined]
  end

  def equipment_join_2016
    join_equipment ResultsParser2016.loadhash_by_county_city
  end

  def equipment_join_2016_fails
    equipment_join_2016.select { |obj| obj[:equipment].nil? }
  end

  def equipment_join_2016_fails_sorted
    equipment_join_2016_fails.map { |x| [x[:returns][0], x[:county], x[:city]] }.sort
  end

  def equipment_join_2012
    join_equipment ResultsParser2012.loadhash_by_county_city
  end

  def equipment_join_2012_fails
    equipment_join_2012.select { |obj| obj[:equipment].nil? }
  end

  def equipment_join_2012_fails_sorted
    equipment_join_2012_fails.map { |x| [x[:returns][0], x[:county], x[:city]] }.sort
  end
end

class JoinEquipmentResults
  extend JoinEquipmentResultHelpers
end
