require_relative('CommandTemplate')

class NullCommand < CommandTemplate
    def execute token
      token.add_header({:header => 'NullCommand', :value => 'OK'})
      token
    end
end
