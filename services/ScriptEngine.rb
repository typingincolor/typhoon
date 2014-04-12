require_relative('../commands/Token')

class ScriptEngine
  def run script
    token = Token.new

    command_factory = CommandFactory.new

    test = JSON.parse script
    test.each do |key, array|
      command = command_factory.build array
      command.execute token
    end

    token.get.to_json
  end
end
