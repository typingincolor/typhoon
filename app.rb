require 'sinatra'
require 'json'
require 'erb'
require 'net/smtp'
require 'rest_client'
require 'mongo'

include Mongo

db = MongoClient.new("localhost").db("script_engine")

configure do
  set :views, "#{File.dirname(__FILE__)}/views"
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

  logger.info payload
  if payload["action"] == "send_email"
    logger.info payload["data"]
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

end

def run_command(command, previous)
  logger.info(command)

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
  opts = {}
  to                 ||= command["data"]["to"]
  opts[:server]      ||= 'localhost'
  opts[:port]        ||= 8025
  opts[:from]        ||= 'email@example.com'
  opts[:from_alias]  ||= 'Example Emailer'
  opts[:subject]     ||= command["data"]["subject"]
  opts[:body]        ||= previous

  msg = <<END_OF_MESSAGE
From: #{opts[:from_alias]} <#{opts[:from]}>
To: <#{to}>
Subject: #{opts[:subject]}

#{opts[:body]}
END_OF_MESSAGE

  Net::SMTP.start(opts[:server], opts[:port]) do |smtp|
    smtp.send_message msg, opts[:from], to
  end

  return previous
end

def concatenate_command(command, previous)
    string_to_concatenate = command["data"]["string"]
    return "#{previous}#{string_to_concatenate}"
end
