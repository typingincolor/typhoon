class CommandFactory
  def build command
    if command['command'] == 'erb'
      return ErbCommand.new command
    elsif command['command'] == 'email'
      return EmailCommand.new command
    elsif command['command'] == 'concatenate'
      return ConcatenateCommand.new command
    else
      return NullCommand.new command
    end
  end
end
