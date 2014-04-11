require 'mail'
require_relative 'CommandTemplate'

Mail.defaults do
  delivery_method :smtp, address: "localhost", port: 8025
end

class EmailCommand < CommandTemplate
    def execute token
      mail = Mail.new
      mail[:from] = 'email@example.com'
      mail[:to] = @command["data"]["to"]
      mail[:subject] = @command["data"]["subject"]
      mail[:body] = token.get_body

      mail.deliver

      token.add_header({:header => "EmailCommand", :value => "OK"})
      token.set_body mail.to_s
      token
    end
end
