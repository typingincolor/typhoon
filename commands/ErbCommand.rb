require 'erb'
require 'tilt'
require_relative 'CommandTemplate'

class ErbCommand < CommandTemplate
  ALLOWED_TEMPLATES = %w[email payment_receipt notification].freeze

  def initialize(command)
    super
    validate_required_data_keys!('template', 'template_data')

    # Prevent path traversal attacks - validate early
    template_name = command['data']['template']
    unless ALLOWED_TEMPLATES.include?(template_name)
      raise Typhoon::ValidationError, "Template '#{template_name}' is not allowed. Allowed templates: #{ALLOWED_TEMPLATES.join(', ')}"
    end
  end

  def execute(token)
    template_name = command['data']['template']
    template_data = command['data']['template_data']

    template_path = File.join('views', "#{template_name}.erb")

    # Additional safety check
    raise Typhoon::ValidationError, 'Invalid template path' unless File.exist?(template_path)

    template = Tilt::ERBTemplate.new(template_path)
    rendered_body = template.render(self, template_data)

    token.add_header(header: 'ErbCommand', value: 'OK')
    token.set_body(rendered_body)
    token
  end
end
