require_relative '../spec_helper'

RSpec.describe ScriptFactory do
  let(:store) { Moneta.new(:Memory) }
  let(:factory) { ScriptFactory.new(store) }

  describe '#initialize' do
    it 'accepts a store' do
      expect { ScriptFactory.new(store) }.not_to raise_error
    end
  end

  describe '#build' do
    before do
      # Create test template with safe navigation for missing data
      FileUtils.mkdir_p('views') unless Dir.exist?('views')
      File.write('views/email_script.erb', 'Email to: <%= defined?(to) ? to : "" %>, Subject: <%= defined?(subject) ? subject : "" %>')
    end

    after do
      File.delete('views/email_script.erb') if File.exist?('views/email_script.erb')
    end

    context 'with send_email action' do
      let(:request) do
        {
          'action' => 'send_email',
          'data' => {
            'to' => 'test@example.com',
            'subject' => 'Test Email',
            'name' => 'Test User'
          }
        }
      end

      it 'generates a script' do
        script_id = factory.build(request)

        expect(script_id).not_to be_nil
        expect(script_id).to match(/^\d+$/)
      end

      it 'stores the script in the store' do
        script_id = factory.build(request)
        stored_script = store[script_id]

        expect(stored_script).not_to be_nil
        expect(stored_script).to be_a(String)
      end

      it 'increments counter for each script' do
        id1 = factory.build(request)
        id2 = factory.build(request)

        expect(id2.to_i).to eq(id1.to_i + 1)
      end

      it 'renders ERB template with data' do
        script_id = factory.build(request)
        script = store[script_id]

        expect(script).to include('test@example.com')
        expect(script).to include('Test Email')
      end

      it 'handles missing template data gracefully' do
        request_minimal = {
          'action' => 'send_email',
          'data' => {}
        }

        expect { factory.build(request_minimal) }.not_to raise_error
      end
    end

    context 'with unknown action' do
      let(:request) do
        {
          'action' => 'unknown_action',
          'data' => {}
        }
      end

      it 'raises ScriptGenerationError' do
        expect { factory.build(request) }.to raise_error(ScriptFactory::ScriptGenerationError)
      end

      it 'includes action name in error message' do
        expect { factory.build(request) }.to raise_error(
          ScriptFactory::ScriptGenerationError,
          /unknown_action/
        )
      end

      it 'lists supported actions in error message' do
        expect { factory.build(request) }.to raise_error(
          ScriptFactory::ScriptGenerationError,
          /Supported actions: send_email/
        )
      end
    end

    context 'error handling' do
      let(:request) do
        {
          'action' => 'send_email',
          'data' => { 'to' => 'test@example.com' }
        }
      end

      it 'raises ScriptGenerationError if template is missing' do
        # Remove template if it exists
        File.delete('views/email_script.erb') if File.exist?('views/email_script.erb')

        expect { factory.build(request) }.to raise_error(ScriptFactory::ScriptGenerationError)
      end

      it 'includes original error in ScriptGenerationError' do
        File.delete('views/email_script.erb') if File.exist?('views/email_script.erb')

        expect { factory.build(request) }.to raise_error(
          ScriptFactory::ScriptGenerationError,
          /Failed to generate script/
        )
      end

      it 'logs error when generation fails' do
        File.delete('views/email_script.erb') if File.exist?('views/email_script.erb')

        expect(LOGGER).to receive(:error).with(/Script generation failed/)

        begin
          factory.build(request)
        rescue ScriptFactory::ScriptGenerationError
          # Expected
        end
      end
    end
  end

  describe '#get' do
    it 'retrieves a stored script' do
      script_content = '{"test": "script"}'
      store['test_id'] = script_content

      result = factory.get('test_id')

      expect(result).to eq(script_content)
    end

    it 'raises ArgumentError for non-existent script' do
      expect { factory.get('nonexistent') }.to raise_error(
        ArgumentError,
        /Script with id 'nonexistent' not found/
      )
    end

    it 'includes script id in error message' do
      expect { factory.get('missing_123') }.to raise_error(/missing_123/)
    end
  end

  describe '.supported_actions' do
    it 'returns array of supported actions' do
      actions = ScriptFactory.supported_actions

      expect(actions).to be_an(Array)
      expect(actions).to include('send_email')
    end

    it 'returns frozen array' do
      actions = ScriptFactory.supported_actions

      expect(actions).to be_frozen
    end
  end

  describe 'integration' do
    before do
      FileUtils.mkdir_p('views') unless Dir.exist?('views')
      File.write('views/email_script.erb', 'Email to: <%= to %>')
    end

    after do
      File.delete('views/email_script.erb') if File.exist?('views/email_script.erb')
    end

    it 'can build and retrieve a script' do
      request = {
        'action' => 'send_email',
        'data' => { 'to' => 'user@example.com', 'subject' => 'Hi' }
      }

      script_id = factory.build(request)
      script = factory.get(script_id)

      expect(script).to include('user@example.com')
    end

    it 'maintains separate scripts for multiple builds' do
      request1 = {
        'action' => 'send_email',
        'data' => { 'to' => 'user1@example.com', 'subject' => 'Test' }
      }
      request2 = {
        'action' => 'send_email',
        'data' => { 'to' => 'user2@example.com', 'subject' => 'Test' }
      }

      id1 = factory.build(request1)
      id2 = factory.build(request2)

      script1 = factory.get(id1)
      script2 = factory.get(id2)

      expect(script1).to include('user1@example.com')
      expect(script2).to include('user2@example.com')
      expect(script1).not_to eq(script2)
    end
  end
end
