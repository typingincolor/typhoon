require_relative '../lib/errors'

class CommandTemplate
  attr_reader :command

  def initialize(command)
    @command = command
    validate_command!
  end

  def execute(token)
    raise NotImplementedError, "#{self.class.name} must implement #execute"
  end

  protected

  def validate_command!
    raise Typhoon::ValidationError, 'Command data is required' unless command.is_a?(Hash)
    raise Typhoon::ValidationError, 'Command must have a "command" key' unless command['command']
    raise Typhoon::ValidationError, 'Command must have a "data" key' unless command['data']
  end

  def validate_required_data_keys!(*keys)
    missing = keys - command['data'].keys
    raise Typhoon::ValidationError, "Missing required data keys: #{missing.join(', ')}" if missing.any?
  end
end
