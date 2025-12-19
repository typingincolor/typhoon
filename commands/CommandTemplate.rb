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
    raise ArgumentError, 'Command data is required' unless command.is_a?(Hash)
    raise ArgumentError, 'Command must have a "command" key' unless command['command']
    raise ArgumentError, 'Command must have a "data" key' unless command['data']
  end

  def validate_required_data_keys!(*keys)
    missing = keys - command['data'].keys
    raise ArgumentError, "Missing required data keys: #{missing.join(', ')}" if missing.any?
  end
end
