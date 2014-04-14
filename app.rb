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

DataMapper.setup(:default, ENV['DATABASE_URL'] || "sqlite3://#{Dir.pwd}/#{ENV['RACK_ENV']}.sqlite")
DataMapper.finalize

if settings.test?
  store = Moneta.new :Memory
else
  store = Moneta.new :File, dir: 'moneta'
end

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
  script_factory = ScriptFactory.new store
  script_engine = ScriptEngine.new

  script = script_factory.get params[:id]
  script_engine.run script
end

post '/script/factory' do
  content_type :json
  request.body.rewind
  payload = JSON.parse request.body.read

  hostname = request.host

  if !JSON::Validator.validate factory_schema, payload
    halt 500, 'Invalid factory request'
  end

  script_factory = ScriptFactory.new store

  id = script_factory.build payload

  if env['HTTP_X_FORWARDED_FOR'] == nil
    hostname = request.host
    port = settings.port
    protocol = env['rack.url_scheme']
  else
    hostname = env['HTTP_X_FORWARDED_HOST']
    port = env['HTTP_X_FORWARDED_PORT']
    protocol = env['HTTP_X_FORWARDED_PROTO']
  end

  {:_id => "#{id}", :run => "#{protocol}://#{hostname}:#{port}/script/#{id}/run", :script => "#{protocol}://#{hostname}:#{port}/script/#{id}"}.to_json
end

get '/script/:id' do
  content_type :json
  script_factory = ScriptFactory.new store
  script = script_factory.get params[:id]
  if !script
    404
  else
    script
  end
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
