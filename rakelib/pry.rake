desc "start a pry shell in the context of the app."
task :pry do
  load 'config/app.rb'
  reload!
  require 'pry'
  binding.pry
end

desc "start an IRB shell in the context of the app."
task :irb do
  require 'irb'
  load 'config/app.rb'
  reload!
  ARGV.clear
  IRB.start
end
