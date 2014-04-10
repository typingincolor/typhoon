require 'mail'
require_relative 'CommandTemplate'

Mail.defaults do
  delivery_method :smtp, address: "localhost", port: 8025
end

class EmailCommand < CommandTemplate
    def execute previous
      puts @command["data"]["to"]
      mail = Mail.new
      mail[:from] = 'email@example.com'
      mail[:to] = @command["data"]["to"]
      mail[:subject] = @command["data"]["subject"]
      mail[:body] =  previous

      mail.deliver

      return previous
    end
end
