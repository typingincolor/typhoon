require_relative 'CommandTemplate'
class ConcatenateCommand < CommandTemplate
    def execute previous
      string_to_concatenate = @command["data"]["string"]
      return "#{previous}#{string_to_concatenate}"
    end
end
