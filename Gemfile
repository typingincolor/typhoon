source 'https://rubygems.org'

ruby '~> 3.3'

# Web framework
gem 'sinatra', '~> 4.0'
gem 'sinatra-contrib', '~> 4.0'
gem 'puma', '~> 6.0'

# Database
gem 'sequel', '~> 5.75'
gem 'sqlite3', '~> 1.6'

# Background jobs
gem 'sidekiq', '~> 7.2'
gem 'sidekiq-scheduler', '~> 5.0'

# Utilities
gem 'chronic', '~> 0.10'
gem 'moneta', '~> 1.6'
gem 'mail', '~> 2.8'
gem 'http', '~> 5.1'
gem 'json-schema', '~> 4.1'

# Configuration
gem 'dotenv', '~> 2.8'

# Logging
gem 'oj', '~> 3.16'

# Security
gem 'rack-protection', '~> 4.0'
gem 'rack-attack', '~> 6.7'

group :development do
  gem 'rerun', '~> 0.14'
  gem 'rubocop', '~> 1.59', require: false
  gem 'rubocop-performance', '~> 1.20', require: false
  gem 'pry', '~> 0.14'
end

group :test do
  gem 'rspec', '~> 3.12'
  gem 'rack-test', '~> 2.1'
  gem 'factory_bot', '~> 6.4'
  gem 'simplecov', '~> 0.22', require: false
  gem 'webmock', '~> 3.19'
end

group :development, :test do
  gem 'faker', '~> 3.2'
end
