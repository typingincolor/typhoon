require 'sinatra'
require 'json'
require 'erb'
require 'mail'
require 'rest_client'
require 'mongo'

include Mongo

db = MongoClient.new("localhost").db("script_engine")

configure do
  set :views, "#{File.dirname(__FILE__)}/views"
end

Mail.defaults do
  delivery_method :smtp, address: "localhost", port: 8025
end

post '/script/run' do
  request.body.rewind
  request_payload = JSON.parse request.body.read
  result = ""

  request_payload.each do |key, array|
    result = run_command array, result
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

def run_command(command, previous)
  if  command["command"] == "_id"
    return previous
  elsif command["command"] == "erb"
    return erb_command command
  elsif command["command"] == "email"
    return email_command command, previous
  elsif command["command"] == "concatenate"
    return concatenate_command command, previous
  else
    logger.error "unknown command"
  end
end

def erb_command(command)
  template = command["data"]["template"]
  return erb :"#{template}", :locals => command["data"]["template_data"]
end

def email_command(command, previous)
  mail = Mail.new do
      from  'email@example.com'
      to command["data"]["to"]
      subject command["data"]["subject"]
      body previous
  end

  mail.deliver

  return previous
end

def concatenate_command(command, previous)
    string_to_concatenate = command["data"]["string"]
    return "#{previous}#{string_to_concatenate}"
end
