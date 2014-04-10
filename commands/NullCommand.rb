require_relative 'CommandTemplate'
class NullCommand < CommandTemplate
    def execute previous
      return previous
    end
end
