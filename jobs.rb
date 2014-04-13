require 'stalker'
require_relative 'model/Task'
require 'rest_client'
require 'moneta'

@@store = Moneta.new(:File, dir: 'moneta_results')

job 'run.tasks' do |args|
  tasks = Task.all(:at.lte => Time.now, :completed_at => nil)

  puts "Found #{tasks.size} tasks to run"

  tasks.each do |task|
    response = RestClient.get task.url

    puts "Run task #{task.url}, response code: #{response.code}"

    counter = @@store.increment('results').to_s
    @@store[counter] = response.to_json
    task.update(:completed_at => Time.now, :code => response.code, :result => counter)
  end

end
