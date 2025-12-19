require_relative '../spec_helper'
require_relative '../../commands/init'

RSpec.describe CommandFactory do
  let(:factory) { CommandFactory.new }

  describe '#build' do
    it 'builds an ErbCommand for erb command type' do
      command = { 'command' => 'erb', 'data' => { 'template' => 'email', 'template_data' => {} } }
      result = factory.build(command)

      expect(result).to be_a(ErbCommand)
    end

    it 'builds an EmailCommand for email command type' do
      command = { 'command' => 'email', 'data' => { 'to' => 'test@example.com', 'subject' => 'Test' } }
      result = factory.build(command)

      expect(result).to be_a(EmailCommand)
    end

    it 'builds a ConcatenateCommand for concatenate command type' do
      command = { 'command' => 'concatenate', 'data' => { 'string' => 'test' } }
      result = factory.build(command)

      expect(result).to be_a(ConcatenateCommand)
    end

    it 'builds a NullCommand for unknown command types' do
      command = { 'command' => 'unknown', 'data' => {} }
      result = factory.build(command)

      expect(result).to be_a(NullCommand)
    end

    it 'raises error for invalid command structure' do
      expect { factory.build({}) }.to raise_error(Typhoon::ValidationError)
    end
  end

  describe '.available_commands' do
    it 'returns array of available command types' do
      commands = CommandFactory.available_commands

      expect(commands).to include('erb', 'email', 'concatenate')
      expect(commands).to be_an(Array)
    end
  end
end
