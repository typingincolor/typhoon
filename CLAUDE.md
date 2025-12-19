# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Typhoon is a modernized Ruby/Sinatra-based web service implementing a "Maneuverable Web Architecture" with three core components:

1. **'at' service** - Schedules URLs to be called at specified times using natural language date parsing (via chronic gem)
2. **Script factory** - Builds and stores executable scripts that can be invoked via URL
3. **Script engine** - Executes scripts using a Command pattern with a Token-based data pipeline

**Recent Modernization**: This codebase was recently modernized from Ruby 2.x/Sinatra 1.x to Ruby 3.3/Sinatra 4.x with modern patterns, security fixes, and improved architecture.

## Development Commands

### Setup

1. Install dependencies:
```bash
bundle install
```

2. Configure environment:
```bash
cp .env.example .env
# Edit .env with your configuration
```

3. Create database:
```bash
bundle exec rake db:create
```

### Running the Application

The application requires Redis for Sidekiq:
```bash
brew install redis  # If not installed
redis-server &
foreman start
```

This starts two processes (defined in Procfile):
- `web`: Puma web server on port 4567
- `worker`: Sidekiq background job processor

### Testing

Run RSpec test suite (180 examples, 94.35% coverage):
```bash
bundle exec rspec
```

Run with detailed output:
```bash
bundle exec rspec --format documentation
```

Run legacy integration tests:
```bash
bundle exec ruby IntegrationTest.rb
```

Run mutation tests (requires mutant license):
```bash
bundle exec mutant run
```

Run linter:
```bash
bundle exec rubocop
```

Auto-fix linting issues:
```bash
bundle exec rubocop -A
```

View test coverage report:
```bash
open coverage/index.html
```

### Common Rake Tasks

```bash
bundle exec rake db:info      # Show database statistics
bundle exec rake db:reset     # Reset database (drop and recreate)
```

## Architecture

### Request Flow

1. **POST /script/factory** - Creates a script from a template and stores it in Moneta key-value store, returns URLs for execution
2. **POST /at** - Schedules a URL to be called at a specific time, stores Task in SQLite via Sequel
3. **Sidekiq-Scheduler** - Triggers TaskExecutorWorker every 20 seconds
4. **TaskExecutorWorker** (workers/task_executor_worker.rb) - Finds pending tasks, executes them via HTTP GET, stores results

### Modern Stack

- **Web Server**: Puma (multi-threaded, production-ready)
- **ORM**: Sequel (modern, maintained alternative to DataMapper)
- **Background Jobs**: Sidekiq with Redis (reliable, feature-rich)
- **HTTP Client**: HTTP gem (modern alternative to RestClient)
- **Configuration**: dotenv + YAML for environment-based config

### Command Pattern Implementation

The ScriptEngine uses a pipeline pattern with Commands and a Token object:

- **Token** (commands/Token.rb) - Data carrier object that flows through command chain, holds headers and body. Now uses keyword arguments and returns self for chaining.
- **CommandTemplate** - Abstract base class for all commands with validation support
- **CommandFactory** - Factory that instantiates concrete commands with a COMMAND_MAP constant
- **ScriptEngine** - Parses and validates JSON scripts, builds commands via factory, executes each with comprehensive error handling

Available commands:
- **ErbCommand** - Renders ERB templates (whitelist-protected against path traversal)
- **EmailCommand** - Sends emails with validation
- **ConcatenateCommand** - Concatenates strings to token body
- **NullCommand** - No-op command

Scripts are JSON objects with string keys, each containing a command type and data. Commands execute in sequence, mutating the Token as they run.

### Storage

- **SQLite** (via Sequel) - Stores Tasks with scheduled execution times, includes timestamps and validation
- **Moneta** - Key-value store for scripts and results
  - `moneta/` directory - Stores generated scripts
  - `moneta_results/` directory - Stores task execution results with full response data

### Configuration

- **config/settings.yml** - Environment-based YAML configuration
- **config/config.rb** - Configuration loader with ERB support
- **config/database.rb** - Database setup with Sequel
- **config/logger.rb** - Structured JSON logging
- **.env file** - Local environment variables (see .env.example)

Environment variables:
- `RACK_ENV` - Application environment (development/test/production)
- `DATABASE_URL` - Database connection string
- `REDIS_URL` - Redis connection for Sidekiq
- `SMTP_*` - Email configuration for production

## Key Files

### Application Core
- `app.rb` - Main Sinatra application class with comprehensive error handling and REST endpoints
- `config.ru` - Rack configuration file for running with Puma

### Services
- `services/ScriptEngine.rb` - Executes scripts with validation and error handling
- `services/ScriptFactory.rb` - Builds scripts from templates with security checks

### Commands (Command Pattern)
- `commands/CommandTemplate.rb` - Base class with validation methods
- `commands/CommandFactory.rb` - Factory with COMMAND_MAP for instantiation
- `commands/ErbCommand.rb` - ERB template rendering (path traversal protected)
- `commands/EmailCommand.rb` - Email sending with validation
- `commands/ConcatenateCommand.rb` - String concatenation
- `commands/NullCommand.rb` - No-op command
- `commands/Token.rb` - Data carrier object

### Models
- `model/Task.rb` - Sequel model for scheduled tasks with validation and helper methods

### Workers
- `workers/task_executor_worker.rb` - Sidekiq worker that executes scheduled tasks

### Configuration
- `config/config.rb` - Configuration loader
- `config/database.rb` - Database setup and table creation
- `config/logger.rb` - Structured JSON logging
- `config/settings.yml` - Environment-based settings
- `config/puma.rb` - Puma web server configuration
- `config/sidekiq.yml` - Sidekiq worker and schedule configuration

### Testing
- `spec/` - RSpec test suite (180 examples, 94.35% coverage)
  - `spec/spec_helper.rb` - RSpec configuration with SimpleCov
  - `spec/commands/` - Command pattern tests (Token, CommandFactory, Email, ERB, etc.)
  - `spec/services/` - ScriptEngine and ScriptFactory tests
  - `spec/model/` - Task model tests
  - `spec/config/` - Configuration and logger tests
  - `spec/app_spec.rb` - Sinatra application integration tests
  - `spec/workers/` - TaskExecutorWorker tests
- `IntegrationTest.rb` - Legacy integration test suite
- `.rspec` - RSpec configuration file
- `.mutant.yml` - Mutation testing configuration
- `coverage/` - SimpleCov HTML coverage reports (gitignored)

**Test Coverage Summary:**
- 180 examples, 0 failures
- 94.35% line coverage (384/407 lines)
- 13 files with 100% coverage (all commands, services, models, config)
- app.rb: 83.48% (production config and proxy scenarios not tested)
- workers/task_executor_worker.rb: 90.00%

## Security Improvements

### Path Traversal Protection
- ErbCommand uses a whitelist of allowed templates (ALLOWED_TEMPLATES constant)
- File existence checks before rendering
- Template names validated against whitelist

### Input Validation
- JSON schema validation on all POST endpoints
- Email address format validation
- URL format validation in Task model
- Required field validation in commands

### Error Handling
- Custom error classes (ScriptExecutionError, UnknownActionError, etc.)
- Proper HTTP status codes (400 for client errors, 500 for server errors)
- Sensitive error details hidden from API responses
- Comprehensive logging for debugging

## Error Handling Patterns

When adding new endpoints or commands:

1. Use specific error classes for different failure modes
2. Add error handlers in app.rb for new error types
3. Return appropriate HTTP status codes:
   - 400: Bad Request (invalid input)
   - 404: Not Found
   - 422: Unprocessable Entity (validation failed)
   - 500: Internal Server Error
4. Log errors with LOGGER before raising or in error handlers
5. Never expose internal details (stack traces, paths) in API responses

## Adding New Commands

To add a new command type:

1. Create new class inheriting from CommandTemplate in `commands/`
2. Implement `execute(token)` method
3. Add validation in `initialize` using `validate_required_data_keys!`
4. Add to CommandFactory::COMMAND_MAP
5. Add tests in IntegrationTest.rb
6. Update ErbCommand::ALLOWED_TEMPLATES if using templates

## Example Usage

See `examples/` directory for JSON request examples:
- `test_factory_call.json` - Create email script
- `test_at_call.json` - Schedule URL execution
- `test_script.json` - Direct script execution format
