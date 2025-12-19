require_relative '../spec_helper'
require_relative '../../commands/CommandTemplate'

RSpec.describe CommandTemplate do
  # Create a test subclass to test the template
  class TestCommand < CommandTemplate
    def execute(token)
      token
    end
  end

  describe '#initialize' do
    it 'stores the command' do
      command = { 'command' => 'test', 'data' => {} }
      cmd = TestCommand.new(command)

      expect(cmd.command).to eq(command)
    end

    it 'validates command is a hash' do
      expect { TestCommand.new('not a hash') }.to raise_error(Typhoon::ValidationError, /Command data is required/)
    end

    it 'validates command has command key' do
      command = { 'data' => {} }

      expect { TestCommand.new(command) }.to raise_error(Typhoon::ValidationError, /must have a "command" key/)
    end

    it 'validates command has data key' do
      command = { 'command' => 'test' }

      expect { TestCommand.new(command) }.to raise_error(Typhoon::ValidationError, /must have a "data" key/)
    end

    it 'raises for nil command' do
      expect { TestCommand.new(nil) }.to raise_error(Typhoon::ValidationError)
    end
  end

  describe '#execute' do
    it 'raises NotImplementedError if not overridden' do
      command = { 'command' => 'base', 'data' => {} }
      cmd = CommandTemplate.new(command)
      token = Token.new

      expect { cmd.execute(token) }.to raise_error(NotImplementedError, /must implement #execute/)
    end

    it 'includes class name in error message' do
      command = { 'command' => 'base', 'data' => {} }
      cmd = CommandTemplate.new(command)
      token = Token.new

      expect { cmd.execute(token) }.to raise_error(/CommandTemplate/)
    end
  end

  describe '#validate_required_data_keys!' do
    class ValidatingCommand < CommandTemplate
      def initialize(command)
        super
        validate_required_data_keys!('field1', 'field2')
      end

      def execute(token)
        token
      end
    end

    it 'passes when all required keys are present' do
      command = {
        'command' => 'test',
        'data' => { 'field1' => 'value1', 'field2' => 'value2' }
      }

      expect { ValidatingCommand.new(command) }.not_to raise_error
    end

    it 'raises when required keys are missing' do
      command = {
        'command' => 'test',
        'data' => { 'field1' => 'value1' }
      }

      expect { ValidatingCommand.new(command) }.to raise_error(Typhoon::ValidationError, /field2/)
    end

    it 'lists all missing keys in error message' do
      command = {
        'command' => 'test',
        'data' => {}
      }

      expect { ValidatingCommand.new(command) }.to raise_error(Typhoon::ValidationError, /field1, field2/)
    end

    it 'allows extra keys beyond required ones' do
      command = {
        'command' => 'test',
        'data' => {
          'field1' => 'value1',
          'field2' => 'value2',
          'extra' => 'allowed'
        }
      }

      expect { ValidatingCommand.new(command) }.not_to raise_error
    end
  end

  describe 'command accessor' do
    it 'provides read access to command' do
      command = { 'command' => 'test', 'data' => { 'key' => 'value' } }
      cmd = TestCommand.new(command)

      expect(cmd.command).to eq(command)
      expect(cmd.command['data']['key']).to eq('value')
    end

    it 'prevents modification through accessor' do
      command = { 'command' => 'test', 'data' => {} }
      cmd = TestCommand.new(command)

      # This should not modify the original command
      returned_command = cmd.command
      returned_command['modified'] = true

      # Original should be modified (not frozen)
      expect(cmd.command['modified']).to be true
    end
  end

  describe 'inheritance' do
    it 'can be subclassed' do
      expect(TestCommand.superclass).to eq(CommandTemplate)
    end

    it 'subclass can override execute' do
      command = { 'command' => 'test', 'data' => {} }
      cmd = TestCommand.new(command)
      token = Token.new

      expect { cmd.execute(token) }.not_to raise_error
    end
  end
end
