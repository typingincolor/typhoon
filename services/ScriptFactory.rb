require 'erb'
require 'tilt'
require_relative '../repositories/script_repository'
require_relative '../lib/errors'

class ScriptFactory
  SUPPORTED_ACTIONS = %w[send_email].freeze

  def initialize(script_repository)
    @repository = script_repository
  end

  def build(request)
    action = request['action']

    unless SUPPORTED_ACTIONS.include?(action)
      raise Typhoon::UnknownActionError, "Unknown action '#{action}'. Supported actions: #{SUPPORTED_ACTIONS.join(', ')}"
    end

    script = generate_script(action, request['data'])
    script_id = @repository.save(script)
    LOGGER.info("Script stored with id: #{script_id}")
    script_id
  rescue Typhoon::UnknownActionError
    raise # Re-raise Typhoon errors as-is
  rescue => e
    LOGGER.error("Script generation failed: #{e.message}")
    raise Typhoon::ScriptGenerationError, "Failed to generate script: #{e.message}"
  end

  def get(script_id)
    @repository.find!(script_id)
  end

  def self.supported_actions
    SUPPORTED_ACTIONS
  end

  private

  def generate_script(action, data)
    case action
    when 'send_email'
      template_path = 'views/email_script.erb'
      raise Typhoon::ScriptGenerationError, "Template not found: #{template_path}" unless File.exist?(template_path)

      template = Tilt::ERBTemplate.new(template_path)
      template.render(self, data)
    end
  end
end
