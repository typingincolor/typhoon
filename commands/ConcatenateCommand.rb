require_relative 'CommandTemplate'

class ConcatenateCommand < CommandTemplate
  def initialize(command)
    super
    validate_required_data_keys!('string')
  end

  def execute(token)
    string_to_concatenate = command['data']['string']
    current_body = token.get_body

    token.add_header(header: 'ConcatenateCommand', value: 'OK')
    token.set_body("#{current_body}#{string_to_concatenate}")
    token
  end
end
