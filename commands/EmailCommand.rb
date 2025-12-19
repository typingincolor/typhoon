require_relative 'CommandTemplate'
require 'mail'

class EmailCommand < CommandTemplate
  def initialize(command)
    super
    validate_required_data_keys!('to', 'subject')
    validate_email_address!(command['data']['to'])
  end

  def execute(token)
    mail = Mail.new do
      from    email_config[:from]
      to      command['data']['to']
      subject command['data']['subject']
      body    token.get_body
    end

    mail.deliver!

    token.add_header(header: 'EmailCommand', value: 'OK')
    token.set_body(mail.to_s)
    token
  rescue => e
    LOGGER.error("Failed to send email: #{e.message}")
    raise StandardError, "Email delivery failed: #{e.message}"
  end

  private

  def email_config
    @email_config ||= begin
      require_relative '../config/config'
      Config.email
    end
  end

  def validate_email_address!(email)
    email_regex = /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i
    raise ArgumentError, "Invalid email address: #{email}" unless email =~ email_regex
  end
end
