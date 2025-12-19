require_relative '../spec_helper'

RSpec.describe ScriptEngine do
  let(:engine) { ScriptEngine.new }

  describe '#run' do
    it 'executes a simple script' do
      script = {
        'step1' => {
          'command' => 'concatenate',
          'data' => { 'string' => 'Hello' }
        }
      }

      result = JSON.parse(engine.run(script))

      expect(result['body']).to eq('Hello')
    end

    it 'executes multiple commands in sequence' do
      script = {
        'step1' => {
          'command' => 'concatenate',
          'data' => { 'string' => 'Hello' }
        },
        'step2' => {
          'command' => 'concatenate',
          'data' => { 'string' => ' World' }
        }
      }

      result = JSON.parse(engine.run(script))

      expect(result['body']).to eq('Hello World')
    end

    it 'accepts JSON string as input' do
      script_json = '{"step1":{"command":"concatenate","data":{"string":"Test"}}}'

      result = JSON.parse(engine.run(script_json))

      expect(result['body']).to eq('Test')
    end

    it 'accepts hash as input' do
      script = { 'step1' => { 'command' => 'concatenate', 'data' => { 'string' => 'Test' } } }

      result = JSON.parse(engine.run(script))

      expect(result['body']).to eq('Test')
    end

    it 'raises ScriptExecutionError for invalid JSON' do
      expect { engine.run('not valid json') }.to raise_error(ScriptEngine::ScriptExecutionError, /Invalid JSON/)
    end

    it 'raises ScriptExecutionError for empty script' do
      expect { engine.run({}) }.to raise_error(ScriptEngine::ScriptExecutionError, /cannot be empty/)
    end

    it 'raises ScriptExecutionError for non-hash script' do
      expect { engine.run([]) }.to raise_error(ScriptEngine::ScriptExecutionError, /must be a hash/)
    end

    it 'raises ScriptExecutionError for command without command field' do
      script = { 'step1' => { 'data' => {} } }

      expect { engine.run(script) }.to raise_error(ScriptEngine::ScriptExecutionError, /missing 'command' field/)
    end

    it 'raises ScriptExecutionError for non-hash command' do
      script = { 'step1' => 'not a hash' }

      expect { engine.run(script) }.to raise_error(ScriptEngine::ScriptExecutionError, /must be a hash/)
    end

    it 'raises ScriptExecutionError when command execution fails' do
      script = {
        'step1' => {
          'command' => 'concatenate',
          'data' => {} # Missing required 'string' field
        }
      }

      expect { engine.run(script) }.to raise_error(ScriptEngine::ScriptExecutionError, /Failed at step/)
    end

    it 'includes failing step name in error message' do
      script = {
        'good_step' => {
          'command' => 'concatenate',
          'data' => { 'string' => 'test' }
        },
        'bad_step' => {
          'command' => 'concatenate',
          'data' => {}
        }
      }

      expect { engine.run(script) }.to raise_error(ScriptEngine::ScriptExecutionError, /bad_step/)
    end
  end

  describe 'command execution order' do
    it 'executes commands in order' do
      script = {
        'first' => { 'command' => 'concatenate', 'data' => { 'string' => '1' } },
        'second' => { 'command' => 'concatenate', 'data' => { 'string' => '2' } },
        'third' => { 'command' => 'concatenate', 'data' => { 'string' => '3' } }
      }

      result = JSON.parse(engine.run(script))

      expect(result['body']).to eq('123')
    end
  end

  describe 'token state persistence' do
    it 'maintains token state across commands' do
      script = {
        'step1' => { 'command' => 'concatenate', 'data' => { 'string' => 'A' } },
        'step2' => { 'command' => 'concatenate', 'data' => { 'string' => 'B' } }
      }

      result = JSON.parse(engine.run(script))

      expect(result['headers'].length).to eq(2)
      expect(result['body']).to eq('AB')
    end
  end
end
