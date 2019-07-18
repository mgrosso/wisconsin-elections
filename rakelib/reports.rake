desc "details of results which could not be matched with equipment"
task :equipment_join_2016_fails do
  load 'config/app.rb'
  reload!
  pp JoinEquipmentResults.equipment_join_2016_fails
end

desc "sorted summary of votes, county, municipality where results could not be matched with equipment"
task :equipment_join_2016_fails_sorted do
  load 'config/app.rb'
  reload!
  p "total votes, county, municipality"
  pp JoinEquipmentResults.equipment_join_2016_fails_sorted
end

desc "details of results which could not be matched with equipment"
task :equipment_join_2012_fails do
  load 'config/app.rb'
  reload!
  pp JoinEquipmentResults.equipment_join_2012_fails
end

desc "sorted summary of votes, county, municipality where results could not be matched with equipment"
task :equipment_join_2012_fails_sorted do
  load 'config/app.rb'
  reload!
  p "total votes, county, municipality"
  pp JoinEquipmentResults.equipment_join_2012_fails_sorted
end
