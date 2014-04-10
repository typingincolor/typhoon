require 'erb'
require 'tilt'
require_relative 'CommandTemplate'

class ERBContext
  def initialize(hash)
    hash.each_pair do |key, value|
      instance_variable_set('@' + key.to_s, value)
    end
  end

  def get_binding
    binding
  end
end

class ErbCommand < CommandTemplate
    def execute previous
      template = @command["data"]["template"]
      #renderer = ERB.new "views/#{template}"
      #erb_context = ERBContext.new @command["data"]["template_data"]
      #return renderer.result erb_context.get_binding
      #return erb :"#{template}", :locals => @command["data"]["template_data"]
      template = Tilt::ERBTemplate.new("views/#{template}.erb")
      template.render self, @command["data"]["template_data"]
    end
end
