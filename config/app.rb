def reload!
  load 'lib/parse_equipment.rb'
  load 'lib/parse_shared.rb'
  load 'lib/etl_checks.rb'
  load 'lib/parse16.rb'
  load 'lib/parse12.rb'
  load 'lib/join_equipment_results.rb'
  load 'lib/errata.rb'
end
