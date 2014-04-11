require_relative '../Token'

class CommandTemplate
  @command = nil

  def initialize command
    @command = command
  end

  def execute token
      raise "must be implemented by a class"
  end
end
