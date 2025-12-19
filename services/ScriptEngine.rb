require_relative '../commands/Token'
require_relative '../commands/CommandFactory'
require_relative '../lib/errors'
require 'json'

class ScriptEngine

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
        raise Typhoon::ScriptExecutionError, "Failed at step '#{key}': #{e.message}"
      end
    end

    LOGGER.info("Script execution completed successfully")
    token.to_json
  end

  private

  def parse_script(script)
    return script if script.is_a?(Hash)

    raise Typhoon::ScriptExecutionError, 'Script must be a hash' unless script.is_a?(String)

    parsed = JSON.parse(script)
    raise Typhoon::ScriptExecutionError, 'Script must be a hash' unless parsed.is_a?(Hash)

    parsed
  rescue JSON::ParserError => e
    raise Typhoon::ScriptExecutionError, "Invalid JSON: #{e.message}"
  end

  def validate_script!(script)
    raise Typhoon::ScriptExecutionError, 'Script must be a hash' unless script.is_a?(Hash)
    raise Typhoon::ScriptExecutionError, 'Script cannot be empty' if script.empty?

    script.each do |key, command_data|
      unless command_data.is_a?(Hash)
        raise Typhoon::ScriptExecutionError, "Command '#{key}' must be a hash"
      end

      unless command_data['command']
        raise Typhoon::ScriptExecutionError, "Command '#{key}' missing 'command' field"
      end
    end
  end
end
