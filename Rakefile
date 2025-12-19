require 'bundler/setup'
require_relative 'config/config'
require_relative 'config/logger'
require_relative 'config/database'

namespace :db do
  desc 'Create database tables'
  task :create do
    puts 'Database tables already created via config/database.rb'
    puts "Tasks table exists: #{DB.table_exists?(:tasks)}"
  end

  desc 'Drop all database tables'
  task :drop do
    DB.drop_table?(:tasks)
    puts 'All tables dropped'
  end

  desc 'Reset database (drop and recreate)'
  task reset: [:drop, :create]

  desc 'Show database info'
  task :info do
    puts "Environment: #{Config.env}"
    puts "Database: #{Config.database[:database]}"
    puts "Tasks count: #{Task.count}"
    puts "Pending tasks: #{Task.where(completed_at: nil).count}"
    puts "Completed tasks: #{Task.exclude(completed_at: nil).count}"
  end
end

namespace :sidekiq do
  desc 'Start Sidekiq'
  task :start do
    exec 'bundle exec sidekiq -r ./workers/task_executor_worker.rb -C config/sidekiq.yml'
  end
end

task default: 'db:info'
