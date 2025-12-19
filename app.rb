require 'sinatra/base'
require 'sinatra/json'
require 'json'
require 'chronic'
require 'json-schema'
require 'moneta'
require 'dotenv/load'

require_relative 'config/config'
require_relative 'config/logger'
require_relative 'config/database'
require_relative 'commands/init'
require_relative 'services/ScriptEngine'
require_relative 'services/ScriptFactory'

class TyphoonApp < Sinatra::Base
  # Configuration
  configure do
    set :show_exceptions, false
    set :raise_errors, false
    set :dump_errors, false
    set :port, Config.app[:port]
    set :bind, Config.app[:host]
  end

  # Setup Moneta store
  configure :test do
    set :moneta_store, Moneta.new(:Memory)
  end

  configure :development, :production do
    set :moneta_store, Moneta.new(:File, dir: Config.moneta[:dir])
  end

  # JSON Schemas
  AT_SCHEMA = {
    'type' => 'object',
    'required' => %w[at url],
    'properties' => {
      'at' => { 'type' => 'string' },
      'url' => { 'type' => 'string', 'format' => 'uri' }
    }
  }.freeze

  FACTORY_SCHEMA = {
    'type' => 'object',
    'required' => %w[action data],
    'properties' => {
      'action' => { 'type' => 'string' },
      'data' => { 'type' => 'object' }
    }
  }.freeze

  # Helpers
  helpers do
    def json_params
      JSON.parse(request.body.read)
    rescue JSON::ParserError => e
      halt 400, json(error: 'Invalid JSON', message: e.message)
    end

    def validate_schema!(payload, schema)
      unless JSON::Validator.validate(schema, payload)
        errors = JSON::Validator.fully_validate(schema, payload)
        halt 400, json(error: 'Validation failed', errors: errors)
      end
    end

    def build_script_urls(id)
      base_url = if request.forwarded?
                   "#{env['HTTP_X_FORWARDED_PROTO']}://#{env['HTTP_X_FORWARDED_HOST']}"
                 else
                   "#{request.scheme}://#{request.host_with_port}"
                 end

      {
        _id: id.to_s,
        run: "#{base_url}/script/#{id}/run",
        script: "#{base_url}/script/#{id}"
      }
    end
  end

  # Error Handlers
  error JSON::ParserError do
    status 400
    json error: 'Invalid JSON', message: env['sinatra.error'].message
  end

  error ScriptEngine::ScriptExecutionError do
    status 422
    json error: 'Script execution failed', message: env['sinatra.error'].message
  end

  error ScriptFactory::UnknownActionError do
    status 400
    json error: 'Unknown action', message: env['sinatra.error'].message
  end

  error ScriptFactory::ScriptGenerationError do
    status 500
    json error: 'Script generation failed', message: env['sinatra.error'].message
  end

  error ArgumentError do
    status 400
    json error: 'Invalid argument', message: env['sinatra.error'].message
  end

  error StandardError do
    LOGGER.error(env['sinatra.error'])
    status 500
    json error: 'Internal server error', message: 'An unexpected error occurred'
  end

  # Health Check
  get '/health' do
    status 200
    json status: 'ok', timestamp: Time.now.utc.iso8601
  end

  # Metrics
  get '/metrics' do
    content_type 'text/plain'
    [
      "# HELP tasks_total Total number of tasks",
      "# TYPE tasks_total gauge",
      "tasks_total #{Task.count}",
      "# HELP tasks_pending Pending tasks",
      "# TYPE tasks_pending gauge",
      "tasks_pending #{Task.where(completed_at: nil).count}",
      "# HELP tasks_completed Completed tasks",
      "# TYPE tasks_completed gauge",
      "tasks_completed #{Task.exclude(completed_at: nil).count}"
    ].join("\n") + "\n"
  end

  # Script Execution
  post '/script/run' do
    request.body.rewind
    payload = json_params

    LOGGER.info('Executing inline script')
    script_engine = ScriptEngine.new
    result = script_engine.run(payload)

    content_type :json
    status 200
    result
  end

  get '/script/:id/run' do
    script_id = params[:id]
    LOGGER.info("Executing stored script: #{script_id}")

    script_factory = ScriptFactory.new(settings.moneta_store)
    script_engine = ScriptEngine.new

    script = script_factory.get(script_id)
    result = script_engine.run(script)

    content_type :json
    status 200
    result
  end

  # Script Factory
  post '/script/factory' do
    request.body.rewind
    payload = json_params
    validate_schema!(payload, FACTORY_SCHEMA)

    LOGGER.info("Creating script for action: #{payload['action']}")
    script_factory = ScriptFactory.new(settings.moneta_store)
    script_id = script_factory.build(payload)

    status 201
    json build_script_urls(script_id)
  end

  get '/script/:id' do
    script_id = params[:id]
    LOGGER.info("Retrieving script: #{script_id}")

    script_factory = ScriptFactory.new(settings.moneta_store)
    script = script_factory.get(script_id)

    content_type :json
    status 200
    script
  end

  # Scheduler
  post '/at' do
    request.body.rewind
    payload = json_params
    validate_schema!(payload, AT_SCHEMA)

    scheduled_time = Chronic.parse(payload['at'], guess: true)

    unless scheduled_time
      halt 400, json(error: 'Invalid time format', message: "Could not parse '#{payload['at']}'")
    end

    task = Task.create(at: scheduled_time, url: payload['url'])

    unless task.valid?
      halt 422, json(error: 'Validation failed', errors: task.errors.full_messages)
    end

    LOGGER.info("Task scheduled for #{scheduled_time}: #{payload['url']}")
    status 202
    json message: 'Task scheduled', task_id: task.id, scheduled_at: scheduled_time.iso8601
  end

  # Catch-all for 404
  not_found do
    json error: 'Not found', path: request.path_info
  end
end
