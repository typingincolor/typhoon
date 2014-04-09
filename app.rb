require 'sinatra'
require 'json'
require 'erb'
require 'net/smtp'
require 'rest_client'

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

post '/script/:id/run' do
  response = RestClient.get 'http://localhost:4567/script/' + params[:id]

  RestClient.post 'http://localhost:4567/script/run', response.to_str, :content_type => :json
end

post '/script/factory' do

end

get '/script/:id' do
    json = <<END_OF_JSON
{
    "one": {
        "command": "erb",
        "data": {
            "template": "email",
            "template_data": {
                "name": "Andrew"
            }
        }
    },
    "two": {
        "command": "email",
        "data": {
            "to": "abraithw@gmail.com",
          	"subject": "test email"
        }
    }
}
END_OF_JSON

  content_type :json
  json
end

post '/at' do

end

def run_command(command, previous)
  logger.info(command)

  if command["command"] == "erb"
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
