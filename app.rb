require 'sinatra'
require 'json'
require 'rest_client'
require 'mongo'

require_relative 'commands/init'

include Mongo

db = MongoClient.new("localhost").db("script_engine")

configure do
  set :views, "#{File.dirname(__FILE__)}/views"
end

post '/script/run' do
  request.body.rewind
  request_payload = JSON.parse request.body.read
  result = ""

  command_factory = CommandFactory.new

  request_payload.each do |key, array|
    command = command_factory.build array
    result = command.execute result
  end

  result
end

get '/script/:id/run' do
  response = RestClient.get 'http://localhost:4567/script/' + params[:id]

  RestClient.post 'http://localhost:4567/script/run', response.to_str, :content_type => :json
end

post '/script/factory' do
  content_type :json
  request.body.rewind
  payload = JSON.parse request.body.read
  script = ""

  if payload["action"] == "send_email"
    script = erb :email_script, :locals => payload["data"]
  else
    logger.error "unknown action"
    return 500
  end

  # store the script
  coll = db.collection "scripts"
  document = JSON.parse script
  id = coll.insert document

  {:run => "http://localhost:4567/script/#{id}/run", :script => "http://localhost:4567/script/#{id}"}.to_json
end

get '/script/:id' do
  coll = db.collection "scripts"
  document = coll.find("_id" => BSON::ObjectId(params[:id])).to_a
  content_type :json
  document[0].to_json
end

post '/at' do
  content_type :json
  request.body.rewind
  payload = JSON.parse request.body.read

  response = RestClient.get payload["url"]

  {:message => "script has been run...", :result => response.to_json}.to_json
end
