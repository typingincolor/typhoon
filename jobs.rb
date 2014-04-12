require 'stalker'
require_relative 'model/Task'

job 'run.tasks' do |args|
  tasks = Task.all(:at.lte => Time.now, :completed_at => nil)
  puts "Found #{tasks.size}"
end
