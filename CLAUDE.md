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
redis-server --daemonize yes  # Start Redis in background
foreman start
```

This starts two processes (defined in Procfile):
- `web`: Puma web server on port 4567
- `worker`: Sidekiq background job processor

**Important**: If you don't have foreman installed:
```bash
gem install foreman
```

**Sidekiq Scheduler Requirements**:
- `connection_pool` gem must be < 3.0 for Sidekiq 7.x compatibility (pinned to ~> 2.4 in Gemfile)
- `sidekiq-scheduler` must be required in worker file (workers/task_executor_worker.rb)
- Schedule configuration must be under `:scheduler:` key in config/sidekiq.yml (not top-level `:schedule:`)

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
- **Error Handling**: Unified Typhoon error hierarchy with proper HTTP status codes
- **Repository Pattern**: Abstraction layer for Moneta storage operations

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

### Storage & Repository Pattern

- **SQLite** (via Sequel) - Stores Tasks with scheduled execution times, includes timestamps and validation
- **Moneta** - Key-value store for scripts and results
  - `moneta/` directory - Stores generated scripts
  - `moneta_results/` directory - Stores task execution results with full response data
- **Repository Pattern** - Abstracts storage operations:
  - **MonetaRepository** (repositories/moneta_repository.rb) - Base wrapper for Moneta with consistent find/save/delete API
  - **ScriptRepository** (repositories/script_repository.rb) - Manages script storage with auto-increment IDs
  - **ResultRepository** (repositories/result_repository.rb) - Stores task results as JSON with auto-increment IDs

### Configuration

- **config/settings.yml** - Environment-based YAML configuration
- **config/config.rb** - Configuration loader with ERB support and explicit accessor methods (no method_missing)
- **config/database.rb** - Database setup with Sequel
- **config/logger.rb** - Structured JSON logging
- **.env file** - Local environment variables (see .env.example)
- **lib/constants.rb** - Named constants for magic numbers (HTTP timeouts, logging limits)
- **lib/errors.rb** - Unified error hierarchy with Typhoon::Error base class
- **lib/error_handler.rb** - Generic Sinatra error handler module

Environment variables:
- `RACK_ENV` - Application environment (development/test/production)
- `DATABASE_URL` - Database connection string
- `REDIS_URL` - Redis connection for Sidekiq
- `SMTP_*` - Email configuration for production

## Key Files

### Application Core
- `app.rb` - Main Sinatra application class with Typhoon::ErrorHandler module and REST endpoints
- `config.ru` - Rack configuration file for running with Puma

### Services
- `services/ScriptEngine.rb` - Executes scripts with Typhoon::ScriptExecutionError
- `services/ScriptFactory.rb` - Builds scripts from templates using ScriptRepository

### Repositories
- `repositories/moneta_repository.rb` - Base Moneta wrapper with find/find!/save/delete/increment_counter
- `repositories/script_repository.rb` - Script storage with auto-increment IDs
- `repositories/result_repository.rb` - Task result storage with JSON serialization

### Commands (Command Pattern)
- `commands/CommandTemplate.rb` - Base class with Typhoon::ValidationError for validation failures
- `commands/CommandFactory.rb` - Factory with COMMAND_MAP for instantiation
- `commands/ErbCommand.rb` - ERB template rendering (whitelist-protected, uses Typhoon::ValidationError)
- `commands/EmailCommand.rb` - Email sending with Typhoon::ValidationError and Typhoon::ServerError
- `commands/ConcatenateCommand.rb` - String concatenation
- `commands/NullCommand.rb` - No-op command
- `commands/Token.rb` - Data carrier object

### Models
- `model/Task.rb` - Sequel model for scheduled tasks with validation and helper methods

### Workers
- `workers/task_executor_worker.rb` - Sidekiq worker that executes scheduled tasks using ResultRepository

### Configuration & Core Libraries
- `config/config.rb` - Configuration loader with explicit accessors (no method_missing)
- `config/database.rb` - Database setup and table creation
- `config/logger.rb` - Structured JSON logging with TyphoonConstants
- `config/settings.yml` - Environment-based settings
- `config/puma.rb` - Puma web server configuration
- `config/sidekiq.yml` - Sidekiq worker and schedule configuration
- `lib/constants.rb` - TyphoonConstants module (HTTP::TIMEOUT_SECONDS, Logging::BACKTRACE_LIMIT)
- `lib/errors.rb` - Typhoon error hierarchy (Error, ClientError, ServerError, etc.)
- `lib/error_handler.rb` - Generic Sinatra error handler module

### Testing
- `spec/` - RSpec test suite (182 examples, 93.07% coverage)
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
- 182 examples, 0 failures
- 93.07% line coverage (497/534 lines)
- All repositories, commands, services, models, and config have excellent coverage
- app.rb, workers, and error handling fully tested with new Typhoon error hierarchy

## Security Improvements

### Path Traversal Protection
- ErbCommand uses a whitelist of allowed templates (ALLOWED_TEMPLATES constant)
- File existence checks before rendering
- Template names validated against whitelist

### Input Validation
- JSON schema validation on all POST endpoints
- Email address format validation with Typhoon::ValidationError
- URL format validation in Task model
- Required field validation in commands using Typhoon::ValidationError

### Unified Error Handling
- **Typhoon error hierarchy** (lib/errors.rb):
  - `Typhoon::Error` - Base class with status_code, error_type, and to_h methods
  - `Typhoon::ClientError` - 4xx client errors (400 Bad Request)
  - `Typhoon::ServerError` - 5xx server errors (500 Internal Server Error)
  - `Typhoon::ValidationError` - 422 Unprocessable Entity for validation failures
  - `Typhoon::ResourceNotFoundError` - 404 Not Found
  - `Typhoon::UnknownActionError` - 400 Bad Request for unknown script actions
  - `Typhoon::ScriptExecutionError` - 422 for script execution failures
  - `Typhoon::ScriptGenerationError` - 500 for script generation failures
- **Generic error handler** (lib/error_handler.rb) - Single Sinatra module replaces repetitive error handlers
- **Proper HTTP status codes** - Each error class knows its own status code
- **Sensitive error details hidden** - API responses use structured error format
- **Comprehensive logging** - Server errors logged before response, client errors not logged

## Error Handling Patterns

When adding new endpoints or commands:

1. **Use Typhoon error classes** for all errors:
   - `Typhoon::ValidationError` (422) - For validation failures in commands/endpoints
   - `Typhoon::ResourceNotFoundError` (404) - For missing resources
   - `Typhoon::UnknownActionError` (400) - For unknown script actions
   - `Typhoon::ScriptExecutionError` (422) - For script execution failures
   - `Typhoon::ScriptGenerationError` (500) - For script generation failures
   - `Typhoon::ClientError` (400) - For other client errors
   - `Typhoon::ServerError` (500) - For other server errors

2. **No need to add error handlers** - The Typhoon::ErrorHandler module handles all Typhoon errors automatically

3. **Each error knows its HTTP status code** - Call `error.status_code` or rely on automatic handling

4. **Structured error responses** - All Typhoon errors automatically convert to JSON via `to_h` method

5. **Logging** - Server errors (5xx) logged automatically, client errors (4xx) not logged to reduce noise

6. **Never expose internals** - Error messages are user-safe, stack traces never exposed

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
