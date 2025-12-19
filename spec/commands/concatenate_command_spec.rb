require_relative '../spec_helper'
require_relative '../../commands/init'

RSpec.describe ConcatenateCommand do
  describe '#execute' do
    it 'concatenates string to empty token body' do
      command = { 'command' => 'concatenate', 'data' => { 'string' => 'Hello' } }
      cmd = ConcatenateCommand.new(command)
      token = Token.new

      result = cmd.execute(token)

      expect(result.get_body).to eq('Hello')
    end

    it 'concatenates string to existing token body' do
      command = { 'command' => 'concatenate', 'data' => { 'string' => ' World' } }
      cmd = ConcatenateCommand.new(command)
      token = Token.new(body: 'Hello')

      result = cmd.execute(token)

      expect(result.get_body).to eq('Hello World')
    end

    it 'adds header to token' do
      command = { 'command' => 'concatenate', 'data' => { 'string' => 'test' } }
      cmd = ConcatenateCommand.new(command)
      token = Token.new

      result = cmd.execute(token)

      expect(result.headers).to include(hash_including(header: 'ConcatenateCommand', value: 'OK'))
    end

    it 'returns the token' do
      command = { 'command' => 'concatenate', 'data' => { 'string' => 'test' } }
      cmd = ConcatenateCommand.new(command)
      token = Token.new

      result = cmd.execute(token)

      expect(result).to be(token)
    end
  end

  describe 'validation' do
    it 'raises error if string data is missing' do
      command = { 'command' => 'concatenate', 'data' => {} }

      expect { ConcatenateCommand.new(command) }.to raise_error(Typhoon::ValidationError, /string/)
    end

    it 'raises error if command structure is invalid' do
      expect { ConcatenateCommand.new({}) }.to raise_error(Typhoon::ValidationError)
    end
  end
end
