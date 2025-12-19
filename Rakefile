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

namespace :test do
  desc 'Run RSpec tests'
  task :spec do
    sh 'bundle exec rspec'
  end

  desc 'Run integration tests'
  task :integration do
    sh 'bundle exec ruby IntegrationTest.rb'
  end

  desc 'Run all tests'
  task all: [:spec, :integration]

  desc 'Run mutation tests'
  task :mutant do
    sh 'bundle exec mutant run --include lib --require typhoon --use rspec "Token*"'
  end

  desc 'Run tests with coverage'
  task :coverage do
    ENV['COVERAGE'] = 'true'
    Rake::Task['test:spec'].invoke
  end
end

namespace :sidekiq do
  desc 'Start Sidekiq'
  task :start do
    exec 'bundle exec sidekiq -r ./workers/task_executor_worker.rb -C config/sidekiq.yml'
  end
end

task default: 'test:all'
task test: 'test:all'
