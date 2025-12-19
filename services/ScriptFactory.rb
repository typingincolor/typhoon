require 'erb'
require 'tilt'
require 'moneta'

class ScriptFactory
  class UnknownActionError < StandardError; end
  class ScriptGenerationError < StandardError; end

  SUPPORTED_ACTIONS = %w[send_email].freeze

  def initialize(store)
    @store = store
  end

  def build(request)
    action = request['action']

    unless SUPPORTED_ACTIONS.include?(action)
      raise UnknownActionError, "Unknown action '#{action}'. Supported actions: #{SUPPORTED_ACTIONS.join(', ')}"
    end

    script = generate_script(action, request['data'])
    store_script(script)
  rescue => e
    LOGGER.error("Script generation failed: #{e.message}")
    raise ScriptGenerationError, "Failed to generate script: #{e.message}"
  end

  def get(key)
    script = @store[key]
    raise ArgumentError, "Script with id '#{key}' not found" unless script

    script
  end

  def self.supported_actions
    SUPPORTED_ACTIONS
  end

  private

  def generate_script(action, data)
    case action
    when 'send_email'
      template_path = 'views/email_script.erb'
      raise ScriptGenerationError, "Template not found: #{template_path}" unless File.exist?(template_path)

      template = Tilt::ERBTemplate.new(template_path)
      template.render(self, data)
    end
  end

  def store_script(script)
    counter = @store.increment('counter').to_s
    @store[counter] = script
    LOGGER.info("Script stored with id: #{counter}")
    counter
  end
end
