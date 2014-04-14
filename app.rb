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

  script_factory = ScriptFactory.new

  id = script_factory.build payload

  {:run => "http://localhost:#{PORT}/script/#{id}/run", :script => "http://localhost:#{PORT}/script/#{id}"}.to_json
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

  if (!JSON::Validator.validate(at_schema, payload))
    halt 500, "Invalid at request" 
  end

  at = Chronic.parse(payload['at'], :guess => true)

  Task.create(:at => at, :url => payload['url'])

  202
end
