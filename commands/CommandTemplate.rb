class CommandTemplate
  @command = nil
  @previous = nil

  def initialize command
    @command = command
  end

  def execute previous
      raise "must be implemented by a class"
  end
end
