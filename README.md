# Typhoon

A Ruby/Sinatra-based web service implementing part of the [Maneuverable Web Architecture][3] presented at QCon London by [Michael Nygard][1].

## Overview

Typhoon provides three core services that work together to schedule and execute scripts via HTTP:

### 1. 'at' Service

Schedules URLs to be called at a specified time using natural language date parsing via the [chronic][4] gem.

**Endpoint:** `POST /at`

**Example:**
```bash
curl -X POST -d @examples/test_at_call.json http://localhost:4567/at
```

```json
{
  "at": "now",
  "url": "http://localhost:4567/script/534669f6ba8d2c8c91000001/run"
}
```

The URL and execution time are stored in a database. [Beanstalk][6] and [Clockwork][7] handle calling the URL at the scheduled time.

### 2. Script Factory

Builds executable scripts from templates, stores them in a key-value store ([Moneta][8]), and returns URLs to execute them.

**Endpoint:** `POST /script/factory`

**Example:**
```bash
curl -X POST -d @examples/test_factory_call.json http://localhost:4567/script/factory
```

```json
{
  "action": "send_email",
  "data": {
    "to": "abraithw@gmail.com",
    "subject": "Hello",
    "name": "Andrew"
  }
}
```

**Response:**
```json
{
  "_id": "1",
  "run": "http://localhost:4567/script/1/run",
  "script": "http://localhost:4567/script/1"
}
```

### 3. Script Engine

Executes scripts using a command pattern. Scripts are JSON objects with sequentially executed commands.

**Run stored script:** `GET /script/:id/run`

**Run arbitrary script:** `POST /script/run`

**Example:**
```bash
curl -X POST -d @examples/test_script.json http://localhost:4567/script/run
```

```json
{
  "one": {
    "command": "erb",
    "data": {
      "template": "email",
      "template_data": {
        "name": "Andrew"
      }
    }
  },
  "two": {
    "command": "email",
    "data": {
      "to": "abraithw@gmail.com",
      "subject": "test email"
    }
  }
}
```

Available commands: `erb`, `email`, `concatenate`

## Prerequisites

- Ruby 3.2+ (see `.ruby-version`)
- Redis: `brew install redis`
- Bundler: `gem install bundler`

## Setup

1. **Install dependencies:**
   ```bash
   bundle install
   ```

2. **Configure environment:**
   ```bash
   cp .env.example .env
   # Edit .env with your settings
   ```

3. **Create database:**
   ```bash
   bundle exec rake db:create
   ```

## Running the Application

1. **Start Redis (required for Sidekiq):**
   ```bash
   redis-server &
   ```

2. **Start all services using [Foreman][5]:**
   ```bash
   foreman start
   ```

This starts two processes:
- **web**: Puma web server on port 4567
- **worker**: Sidekiq background job processor (checks for tasks every 20 seconds)

## Testing

Run the integration test suite:
```bash
bundle exec ruby IntegrationTest.rb
```

For development with auto-reloading:
```bash
bundle exec rerun 'ruby IntegrationTest.rb'
```

Run RuboCop for linting:
```bash
bundle exec rubocop
```

## API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/health` | Health check endpoint |
| GET | `/metrics` | Prometheus-compatible metrics |
| POST | `/at` | Schedule a URL to be called at a specific time |
| POST | `/script/factory` | Create a new script from a template |
| GET | `/script/:id` | Retrieve a stored script |
| GET | `/script/:id/run` | Execute a stored script |
| POST | `/script/run` | Execute an arbitrary script |

## Architecture (Modernized)

- **Web Server**: Puma with multi-threading support
- **Database**: SQLite with Sequel ORM for scheduled tasks
- **Storage**: Moneta key-value store for scripts and execution results
- **Background Jobs**: Sidekiq with Redis for reliable job processing
- **Scheduling**: Sidekiq-Scheduler for periodic task checks (every 20 seconds)
- **Script Execution**: Command pattern with Token-based data pipeline
- **Configuration**: YAML-based with environment variable support
- **Logging**: Structured JSON logging
- **Error Handling**: Comprehensive error handling with proper HTTP status codes

### Key Improvements from Original

- Migrated from deprecated DataMapper to modern Sequel ORM
- Replaced Beanstalk/Stalker/Clockwork with Sidekiq (single dependency)
- Fixed security vulnerabilities (path traversal, input validation)
- Added health check and metrics endpoints
- Modernized Ruby patterns (keyword arguments, proper error handling)
- Added comprehensive logging and error handling
- Configuration management with dotenv

For more detailed architecture information, see [CLAUDE.md](CLAUDE.md).

## References

 [1]: http://www.michaelnygard.com/
 [2]: http://nilhcem.github.io/FakeSMTP/
 [3]: https://speakerdeck.com/mtnygard/maneuverable-web-architecture
 [4]: https://github.com/mojombo/chronic
 [5]: https://github.com/ddollar/foreman
 [6]: http://kr.github.io/beanstalkd/
 [7]: https://github.com/tomykaira/clockwork
 [8]: https://github.com/minad/moneta
