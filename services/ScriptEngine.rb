require_relative '../commands/Token'
require_relative '../commands/CommandFactory'
require 'json'

class ScriptEngine
  class ScriptExecutionError < StandardError; end

  def run(script)
    token = Token.new
    command_factory = CommandFactory.new

    parsed_script = parse_script(script)
    validate_script!(parsed_script)

    LOGGER.info("Executing script with #{parsed_script.size} commands")

    parsed_script.each_with_index do |(key, command_data), index|
      LOGGER.debug("Executing command #{index + 1}/#{parsed_script.size}: #{command_data['command']}")

      begin
        command = command_factory.build(command_data)
        command.execute(token)
      rescue => e
        LOGGER.error("Command '#{key}' failed: #{e.message}")
        raise ScriptExecutionError, "Failed at step '#{key}': #{e.message}"
      end
    end

    LOGGER.info("Script execution completed successfully")
    token.to_json
  end

  private

  def parse_script(script)
    return script if script.is_a?(Hash)

    JSON.parse(script)
  rescue JSON::ParserError => e
    raise ScriptExecutionError, "Invalid JSON: #{e.message}"
  end

  def validate_script!(script)
    raise ScriptExecutionError, 'Script must be a hash' unless script.is_a?(Hash)
    raise ScriptExecutionError, 'Script cannot be empty' if script.empty?

    script.each do |key, command_data|
      unless command_data.is_a?(Hash)
        raise ScriptExecutionError, "Command '#{key}' must be a hash"
      end

      unless command_data['command']
        raise ScriptExecutionError, "Command '#{key}' missing 'command' field"
      end
    end
  end
end
