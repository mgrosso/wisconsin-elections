desc "details of results which could not be matched with equipment"
task :join_fails do
  load 'config/app.rb'
  reload!
  pp JoinEquipmentResults.join_fails
end

desc "sorted summary of votes, county, municipality where results could not be matched with equipment"
task :join_fails_sorted do
  require 'irb'
  load 'config/app.rb'
  reload!
  p "total votes, county, municipality"
  pp JoinEquipmentResults.join_fails_sorted
end
