# Migration Guide

This document outlines the changes made during the modernization of Typhoon from the legacy codebase to the current version.

## Major Changes

### Dependencies

| Old | New | Reason |
|-----|-----|--------|
| DataMapper | Sequel 5.x | DataMapper is unmaintained since 2011 |
| Thin | Puma 6.x | Modern, multi-threaded web server |
| Beanstalk + Stalker + Clockwork | Sidekiq + Sidekiq-Scheduler | Simpler stack, better monitoring |
| RestClient | HTTP gem | Modern, better API |
| No config management | dotenv + YAML | Proper environment configuration |

### Ruby Version

- **Old**: Ruby 2.x
- **New**: Ruby 3.2+
- Modern Ruby patterns: keyword arguments, pattern matching support

### Removed Files

- `jobs.rb` - Replaced by `workers/task_executor_worker.rb`
- `clock.rb` - Replaced by Sidekiq-Scheduler configuration

### New Files

```
config/
  ├── config.rb           # Configuration loader
  ├── database.rb         # Database setup
  ├── logger.rb           # Structured logging
  ├── puma.rb            # Web server config
  ├── settings.yml        # Environment settings
  └── sidekiq.yml        # Worker config

workers/
  └── task_executor_worker.rb  # Background job processor

.env.example              # Environment variables template
.rubocop.yml             # Linting configuration
Rakefile                 # Rake tasks
config.ru                # Rack configuration
```

## Breaking Changes

### Database

**Before**:
```ruby
require 'data_mapper'
DataMapper.setup(:default, "sqlite3://...")
DataMapper.auto_migrate!
```

**After**:
```ruby
require_relative 'config/database'
# Database setup is automatic
# Use: bundle exec rake db:create
```

### Task Model

**Before**:
```ruby
Task.create(:at => time, :url => url)
Task.all(:at.lte => Time.now, :completed_at => nil)
task.update(:completed_at => Time.now)
```

**After**:
```ruby
Task.create(at: time, url: url)
Task.pending  # Built-in scope
task.mark_completed!(response_code: 200, result_id: '1')
```

### Application Structure

**Before (Sinatra Classic)**:
```ruby
require 'sinatra'
get '/path' do
  # handler
end
```

**After (Sinatra Modular)**:
```ruby
require 'sinatra/base'
class TyphoonApp < Sinatra::Base
  get '/path' do
    # handler
  end
end
```

### Commands

**Before**:
```ruby
class MyCommand < CommandTemplate
  def execute token
    @command['data']['field']
  end
end
```

**After**:
```ruby
class MyCommand < CommandTemplate
  def initialize(command)
    super
    validate_required_data_keys!('field')
  end

  def execute(token)
    command['data']['field']  # Use reader, not instance variable
    # ...
    token  # Must return token
  end
end
```

### Token Usage

**Before**:
```ruby
token.add_header({:header => 'Name', :value => 'Value'})
```

**After**:
```ruby
token.add_header(header: 'Name', value: 'Value')
```

## Configuration Changes

### Environment Setup

**Before**: Hardcoded values, minimal configuration

**After**:
1. Copy `.env.example` to `.env`
2. Edit configuration in `config/settings.yml`
3. Use `Config.app[:port]` to access settings

### Email Configuration

**Before**: Hardcoded in EmailCommand
```ruby
Mail.defaults do
  delivery_method :test
end
```

**After**: Configured per environment
```yaml
# config/settings.yml
development:
  email:
    delivery_method: 'test'

production:
  email:
    delivery_method: 'smtp'
    smtp_settings:
      address: ENV['SMTP_HOST']
```

## Running the Application

### Development

**Before**:
```bash
beanstalkd &
foreman start
```

**After**:
```bash
redis-server &
foreman start
```

### Production

**Before**: Manual process management

**After**: Use systemd, Docker, or Heroku with Procfile:
```
web: bundle exec puma -C config/puma.rb
worker: bundle exec sidekiq -r ./workers/task_executor_worker.rb -C config/sidekiq.yml
```

## Testing Changes

### Test Setup

**Before**:
```ruby
def test_something
  DataMapper.auto_migrate!
  # test code
end
```

**After**:
```ruby
def setup
  Task.where(Sequel.lit('1=1')).delete
end

def test_something
  # test code
end
```

### Assertions

**Before**:
```ruby
assert_equal 500, last_response.status
assert_equal 'Error message', last_response.body
```

**After**:
```ruby
assert_equal 400, last_response.status

response = JSON.parse(last_response.body)
assert_equal 'Validation failed', response['error']
```

## New Features

### Health Check
```bash
curl http://localhost:4567/health
```

### Metrics
```bash
curl http://localhost:4567/metrics
```

### Structured Logging
All logs are now JSON:
```json
{"timestamp":"2024-01-01T00:00:00Z","severity":"INFO","message":"Task scheduled"}
```

### Better Error Messages
API now returns structured error responses:
```json
{
  "error": "Validation failed",
  "errors": ["url is required", "url must be a valid URL"]
}
```

## Security Improvements

1. **Path Traversal Fixed**: ErbCommand now uses whitelist
2. **Input Validation**: All inputs validated with JSON Schema
3. **Email Validation**: Email addresses validated before sending
4. **URL Validation**: URLs validated in Task model
5. **Error Hiding**: Internal errors don't leak implementation details

## Performance Improvements

1. **Multi-threading**: Puma supports concurrent requests
2. **Better Job Processing**: Sidekiq is more efficient than Stalker
3. **Connection Pooling**: Sequel and Sidekiq use connection pools

## Monitoring Improvements

1. **Structured Logging**: JSON logs for easy parsing
2. **Metrics Endpoint**: Prometheus-compatible metrics
3. **Health Check**: Standardized health check endpoint
4. **Sidekiq Web UI**: Available for monitoring jobs

## Migration Checklist

If migrating an existing deployment:

- [ ] Install Redis
- [ ] Remove beanstalkd
- [ ] Update Ruby to 3.2+
- [ ] Run `bundle install` with new Gemfile
- [ ] Copy `.env.example` to `.env` and configure
- [ ] Run `bundle exec rake db:create` (will migrate data automatically)
- [ ] Update process management (Procfile)
- [ ] Test all endpoints
- [ ] Update monitoring/alerting for new metrics endpoint
- [ ] Update log parsing for JSON format

## Rollback Plan

If you need to rollback:

1. Keep a backup of the old codebase
2. Database is compatible (same schema, just different ORM)
3. Moneta storage is unchanged
4. Can export tasks to JSON before migration

## Getting Help

- See [README.md](README.md) for setup instructions
- See [CLAUDE.md](CLAUDE.md) for architecture details
- Check example JSON files in `examples/` directory
- Run tests with `bundle exec ruby IntegrationTest.rb`
