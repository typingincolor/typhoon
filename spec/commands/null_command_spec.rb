require_relative '../spec_helper'
require_relative '../../commands/init'

RSpec.describe NullCommand do
  describe '#execute' do
    it 'does not modify token body' do
      command = { 'command' => 'null', 'data' => {} }
      cmd = NullCommand.new(command)
      token = Token.new(body: 'original body')

      result = cmd.execute(token)

      expect(result.get_body).to eq('original body')
    end

    it 'adds header to token' do
      command = { 'command' => 'null', 'data' => {} }
      cmd = NullCommand.new(command)
      token = Token.new

      result = cmd.execute(token)

      expect(result.headers).to include(hash_including(header: 'NullCommand', value: 'OK'))
    end

    it 'returns the token' do
      command = { 'command' => 'null', 'data' => {} }
      cmd = NullCommand.new(command)
      token = Token.new

      result = cmd.execute(token)

      expect(result).to be(token)
    end

    it 'preserves existing headers' do
      command = { 'command' => 'null', 'data' => {} }
      cmd = NullCommand.new(command)
      token = Token.new.add_header(header: 'Previous', value: 'Command')

      result = cmd.execute(token)

      expect(result.headers.length).to eq(2)
    end

    it 'works with empty token' do
      command = { 'command' => 'null', 'data' => {} }
      cmd = NullCommand.new(command)
      token = Token.new

      result = cmd.execute(token)

      expect(result.get_body).to eq('')
      expect(result.headers.length).to eq(1)
    end
  end

  describe 'initialization' do
    it 'accepts any data' do
      command = { 'command' => 'null', 'data' => { 'random' => 'data' } }

      expect { NullCommand.new(command) }.not_to raise_error
    end

    it 'requires valid command structure' do
      expect { NullCommand.new({}) }.to raise_error(ArgumentError)
    end
  end

  describe 'use as fallback' do
    it 'can be used for unknown commands' do
      factory = CommandFactory.new
      unknown_command = { 'command' => 'does_not_exist', 'data' => {} }

      result = factory.build(unknown_command)

      expect(result).to be_a(NullCommand)
    end
  end
end
