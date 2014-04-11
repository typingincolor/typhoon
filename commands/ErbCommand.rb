require 'erb'
require 'tilt'

require_relative('CommandTemplate')

class ErbCommand < CommandTemplate
    def execute token
      token.add_header({:header => 'ErbCommand', :value => 'OK'})
      template = @command['data']['template']
      template = Tilt::ERBTemplate.new("views/#{template}.erb")
      token.set_body(template.render self, @command['data']['template_data'])
      token
    end
end
