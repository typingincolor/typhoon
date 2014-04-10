require 'erb'
require 'tilt'
require_relative 'CommandTemplate'

class ErbCommand < CommandTemplate
    def execute previous
      template = @command["data"]["template"]
      template = Tilt::ERBTemplate.new("views/#{template}.erb")
      template.render self, @command["data"]["template_data"]
    end
end
