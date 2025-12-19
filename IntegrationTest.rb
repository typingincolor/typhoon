ENV['RACK_ENV'] = 'test'

require_relative './app'
require 'minitest/autorun'
require 'rack/test'
require 'json'

class TyphoonTest < Minitest::Test
  include Rack::Test::Methods

  FACTORY_RESPONSE_SCHEMA = {
    'type' => 'object',
    'required' => %w[_id run script],
    'properties' => {
      '_id' => { 'type' => 'string' },
      'run' => { 'type' => 'string' },
      'script' => { 'type' => 'string' }
    }
  }.freeze

  def app
    TyphoonApp
  end

  def setup
    # Clear database before each test
    Task.where(Sequel.lit('1=1')).delete
  end

  def test_health_check
    get '/health'
    assert last_response.ok?

    response = JSON.parse(last_response.body)
    assert_equal 'ok', response['status']
    assert response['timestamp']
  end

  def test_metrics_endpoint
    get '/metrics'
    assert last_response.ok?
    assert_includes last_response.body, 'tasks_total'
    assert_includes last_response.body, 'tasks_pending'
  end

  def test_script_factory_and_execution
    factory_request = {
      action: 'send_email',
      data: { to: 'test@example.com', subject: 'Hello', name: 'Andrew' }
    }.to_json

    post '/script/factory', factory_request, { 'Content-Type' => 'application/json' }

    assert_equal 201, last_response.status

    response = JSON.parse(last_response.body)
    assert JSON::Validator.validate(FACTORY_RESPONSE_SCHEMA, response), 'Invalid factory response'

    script_id = response['_id']

    # Get the script
    get "/script/#{script_id}"
    assert_equal 200, last_response.status
  end

  def test_script_not_found
    get '/script/not_found'
    assert_equal 400, last_response.status

    response = JSON.parse(last_response.body)
    assert_equal 'Invalid argument', response['error']
  end

  def test_factory_fails_on_bad_request
    bad_request = {
      action: 'send_email',
      rubbish: { to: 'test@example.com' }
    }.to_json

    post '/script/factory', bad_request, { 'Content-Type' => 'application/json' }

    assert_equal 400, last_response.status

    response = JSON.parse(last_response.body)
    assert_equal 'Validation failed', response['error']
  end

  def test_schedule_task
    at_request = { at: 'now', url: 'http://localhost:4567/health' }.to_json

    post '/at', at_request, { 'Content-Type' => 'application/json' }

    assert_equal 202, last_response.status

    response = JSON.parse(last_response.body)
    assert_equal 'Task scheduled', response['message']
    assert response['task_id']
    assert response['scheduled_at']
  end

  def test_bad_at_request
    bad_request = { at: 'now', rubbish: 'sssss' }.to_json

    post '/at', bad_request, { 'Content-Type' => 'application/json' }

    assert_equal 400, last_response.status

    response = JSON.parse(last_response.body)
    assert_equal 'Validation failed', response['error']
  end

  def test_invalid_json
    post '/script/run', 'not valid json', { 'Content-Type' => 'application/json' }

    assert_equal 400, last_response.status

    response = JSON.parse(last_response.body)
    assert_equal 'Invalid JSON', response['error']
  end

  def test_execute_inline_script
    script = {
      'one' => {
        'command' => 'concatenate',
        'data' => { 'string' => 'Hello World' }
      }
    }.to_json

    post '/script/run', script, { 'Content-Type' => 'application/json' }

    assert_equal 200, last_response.status

    response = JSON.parse(last_response.body)
    assert_equal 'Hello World', response['body']
  end

  def test_not_found
    get '/nonexistent'

    assert_equal 404, last_response.status

    response = JSON.parse(last_response.body)
    assert_equal 'Not found', response['error']
  end
end
