require_relative('CommandTemplate')
require 'mail'

Mail.defaults do
  #delivery_method :smtp, address: "localhost", port: 25
  delivery_method :test
end

class EmailCommand < CommandTemplate
    def execute token
      mail = Mail.new
      mail[:from] = 'email@example.com'
      mail[:to] = @command['data']['to']
      mail[:subject] = @command['data']['subject']
      mail[:body] = token.get_body

      mail.deliver

      token.add_header({:header => 'EmailCommand', :value => 'OK'})
      token.set_body mail.to_s
      token
    end
end
