require 'sinatra'
require 'json'
require 'rest_client'

require_relative 'commands/init'
require_relative 'services/ScriptEngine'
require_relative 'services/ScriptFactory'

post '/script/run' do
  request.body.rewind
  script = JSON.parse request.body.read

  script_engine = ScriptEngine.new
  script_engine.run script
end

get '/script/:id/run' do
  response = RestClient.get 'http://localhost:4567/script/' + params[:id]

  RestClient.post 'http://localhost:4567/script/run', response.to_str, :content_type => :json
end

post '/script/factory' do
  content_type :json
  request.body.rewind
  payload = JSON.parse request.body.read

  script_factory = ScriptFactory.new

  id = script_factory.build payload

  {:run => "http://localhost:4567/script/#{id}/run", :script => "http://localhost:4567/script/#{id}"}.to_json
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

  response = RestClient.get payload['url']

  {:message => 'script has been run...', :result => response.to_json}.to_json
end
