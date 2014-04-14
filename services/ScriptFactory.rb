require 'erb'
require 'tilt'
require 'moneta'

class ScriptFactory
  def initialize store
    @@store = store
  end

  def build request
    if request['action'] == 'send_email'
      template = Tilt::ERBTemplate.new('views/email_script.erb')
      script = template.render self, request['data']
    else
      raise 'unknown action'
    end

    # store the script
    counter = @@store.increment('counter').to_s
    @@store[counter] = script
    counter
  end

  def get key
    @@store[key]
  end
end
