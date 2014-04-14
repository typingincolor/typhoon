ENV['RACK_ENV'] = 'test'

require_relative './app'
require 'minitest/autorun'
require 'rack/test'

class TyphoonTest < Minitest::Test
  include Rack::Test::Methods

  @@factory_response_schema = {
    "type" => "object",
    "required" => ["run", "script"],
    "properties" => {
      "_id" => {"type" => "string"},
      "run" => {"type" => "url"},
      "script" => {"type" => "url"}
    }
  }

  def app
    Sinatra::Application
  end

  def test_everything_ok
    DataMapper.auto_migrate!
    factory_request = {:action => 'send_email', :data => {:to => 'abraithw@gmail.com', :subject => 'Hello', :name => 'Andrew'}}.to_json

    post '/script/factory', factory_request, {'Content-Type' => 'application/json'}

    assert last_response.ok?

    assert JSON::Validator.validate(@@factory_response_schema, last_response.body, :strict => true), 'JSON validation failed'

    factory_response = JSON.parse(last_response.body)
    id = factory_response['_id']
    run_command = factory_response['run']

    get "/script/#{id}"
    assert_equal 200, last_response.status

    at_request = {:at => 'now', :url => run_command}.to_json

    post '/at', at_request, {'Content-Type' => 'application/json'}
    assert_equal 202, last_response.status
  end

  def test_script_not_found
    get '/script/not_found'
    assert_equal 404, last_response.status
  end

  def test_factory_fails_on_bad_request
    bad_request = {:action => 'send_email', :rubbish => {:to => 'abraithw@gmail.com', :subject => 'Hello', :name => 'Andrew'}}.to_json

    post '/script/factory', bad_request, {'Content-Type' => 'application/json'}

    assert_equal 500, last_response.status
    assert_equal 'Invalid factory request', last_response.body
  end

  def test_bad_at_request
    bad_request = {:at => 'now', :rubbish => 'sssss'}.to_json

    post '/at', bad_request, {'Content-Type' => 'application/json'}

    assert_equal 500, last_response.status
    assert_equal 'Invalid at request', last_response.body
  end
end
