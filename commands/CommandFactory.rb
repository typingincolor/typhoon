class CommandFactory
  COMMAND_MAP = {
    'erb' => ErbCommand,
    'email' => EmailCommand,
    'concatenate' => ConcatenateCommand
  }.freeze

  def build(command)
    command_type = command['command']
    command_class = COMMAND_MAP[command_type]

    if command_class
      command_class.new(command)
    else
      LOGGER.warn("Unknown command type '#{command_type}', using NullCommand")
      NullCommand.new(command)
    end
  end

  def self.available_commands
    COMMAND_MAP.keys
  end
end
