require 'sinatra'
require 'json'
require 'chronic'
require 'thin'
require 'json-schema'

require_relative 'model/Task.rb'
require_relative 'commands/init'
require_relative 'services/ScriptEngine'
require_relative 'services/ScriptFactory'

PORT = settings.port

at_schema = {
  "type" => "object",
  "required" => ["at", "url"],
  "properties" => {
    "at" => {"type" => "string"},
    "url" => {"type" => "string"}
  }
}

factory_schema = {
  "type" => "object",
  "required" => ["action", "data"],
  "properties" => {
    "action" => {"type" => "string"},
    "data" => {"type" => "object"}
  }
}

post '/script/run' do
  request.body.rewind
  script = JSON.parse request.body.read

  script_engine = ScriptEngine.new
  script_engine.run script
end

get '/script/:id/run' do
  script_factory = ScriptFactory.new
  script_engine = ScriptEngine.new

  script = script_factory.get params[:id]
  script_engine.run script
end

post '/script/factory' do
  content_type :json
  request.body.rewind
  payload = JSON.parse request.body.read

  logger.info request

  hostname = request.host

  if !JSON::Validator.validate factory_schema, payload
    halt 500, 'Invalid factory request'
  end

  script_factory = ScriptFactory.new

  id = script_factory.build payload

  logger.info "HTTP_X_FORWARDED_FOR #{env['HTTP_X_FORWARDED_FOR']}"

  if env['HTTP_X_FORWARDED_FOR'] == nil
    hostname = env['SERVER_NAME']
    port = env['SERVER_PORT']
    protocol = env['rack.url_scheme']
  else
    hostname = env['HTTP_X_FORWARDED_HOST']
    port = env['HTTP_X_FORWARDED_PORT']
    protocol = env['HTTP_X_FORWARDED_PROTO']
  end

  {:run => "#{protocol}://#{hostname}:#{port}/script/#{id}/run", :script => "#{protocol}://#{hostname}:#{port}/script/#{id}"}.to_json
end

get '/script/:id' do
  content_type :json
  script_factory = ScriptFactory.new
  script = script_factory.get params[:id]
  script
end

post '/at' do
  content_type :json
  request.body.rewind
  payload = JSON.parse request.body.read

  if !JSON::Validator.validate at_schema, payload
    halt 500, 'Invalid at request'
  end

  at = Chronic.parse(payload['at'], :guess => true)

  Task.create(:at => at, :url => payload['url'])

  202
end
