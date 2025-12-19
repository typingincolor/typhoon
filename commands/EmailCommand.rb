require_relative 'CommandTemplate'
require 'mail'

class EmailCommand < CommandTemplate
  def initialize(command)
    super
    validate_required_data_keys!('to', 'subject')
    validate_email_address!(command['data']['to'])
  rescue Typhoon::ValidationError
    raise # Re-raise validation errors as-is
  rescue => e
    raise Typhoon::ValidationError, e.message
  end

  def execute(token)
    from_address = email_config[:from]
    to_address = command['data']['to']
    email_subject = command['data']['subject']
    email_body = token.get_body

    mail = Mail.new do
      from    from_address
      to      to_address
      subject email_subject
      body    email_body
    end

    mail.deliver!

    token.add_header(header: 'EmailCommand', value: 'OK')
    token.set_body(mail.to_s)
    token
  rescue => e
    LOGGER.error("Failed to send email: #{e.message}")
    raise Typhoon::ServerError, "Email delivery failed: #{e.message}"
  end

  private

  def email_config
    @email_config ||= begin
      require_relative '../config/config'
      Config.email
    end
  end

  def validate_email_address!(email)
    # Validates email format and prevents consecutive dots
    email_regex = /\A[\w+\-]+(?:\.[\w+\-]+)*@[a-z\d\-]+(?:\.[a-z\d\-]+)*\.[a-z]+\z/i
    raise Typhoon::ValidationError, "Invalid email address: #{email}" unless email =~ email_regex
  end
end
