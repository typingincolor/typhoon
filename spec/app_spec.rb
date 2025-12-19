require_relative 'spec_helper'

RSpec.describe TyphoonApp do
  describe 'GET /health' do
    it 'returns 200 status' do
      get '/health'

      expect(last_response.status).to eq(200)
    end

    it 'returns JSON with status ok' do
      get '/health'

      json = JSON.parse(last_response.body)
      expect(json['status']).to eq('ok')
      expect(json['timestamp']).to match(/\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z/)
    end
  end

  describe 'GET /metrics' do
    it 'returns 200 status' do
      get '/metrics'

      expect(last_response.status).to eq(200)
    end

    it 'returns Prometheus format metrics' do
      Task.create(url: 'http://example.com', at: Time.now)
      Task.create(url: 'http://example.com', at: Time.now, completed_at: Time.now)

      get '/metrics'

      expect(last_response.body).to include('tasks_total 2')
      expect(last_response.body).to include('tasks_pending 1')
      expect(last_response.body).to include('tasks_completed 1')
    end
  end

  describe 'POST /script/run' do
    it 'executes a valid script' do
      script = {
        'step1' => {
          'command' => 'concatenate',
          'data' => { 'string' => 'Test' }
        }
      }

      post '/script/run', script.to_json, { 'CONTENT_TYPE' => 'application/json' }

      expect(last_response.status).to eq(200)
      json = JSON.parse(last_response.body)
      expect(json['body']).to eq('Test')
    end

    it 'returns 400 for invalid JSON' do
      post '/script/run', 'not json', { 'CONTENT_TYPE' => 'application/json' }

      expect(last_response.status).to eq(400)
      json = JSON.parse(last_response.body)
      expect(json['error']).to eq('Invalid JSON')
    end

    it 'returns 422 for script execution error' do
      script = {
        'step1' => {
          'command' => 'concatenate',
          'data' => {}  # Missing required field
        }
      }

      post '/script/run', script.to_json, { 'CONTENT_TYPE' => 'application/json' }

      expect(last_response.status).to eq(422)
      json = JSON.parse(last_response.body)
      expect(json['error']).to eq('Script execution failed')
    end
  end

  describe 'POST /script/factory' do
    before do
      # Create test template with safe navigation for missing data
      FileUtils.mkdir_p('views') unless Dir.exist?('views')
      File.write('views/email_script.erb', 'Email to: <%= defined?(to) ? to : "" %>, Subject: <%= defined?(subject) ? subject : "" %>')
    end

    after do
      File.delete('views/email_script.erb') if File.exist?('views/email_script.erb')
    end

    it 'creates a script and returns URLs' do
      payload = {
        action: 'send_email',
        data: { to: 'test@example.com', subject: 'Test', name: 'User' }
      }

      post '/script/factory', payload.to_json, { 'CONTENT_TYPE' => 'application/json' }

      expect(last_response.status).to eq(201)
      json = JSON.parse(last_response.body)
      expect(json['_id']).not_to be_nil
      expect(json['run']).to include('/script/')
      expect(json['script']).to include('/script/')
    end

    it 'returns error for invalid action' do
      payload = { action: 'unknown_action', data: {} }

      post '/script/factory', payload.to_json, { 'CONTENT_TYPE' => 'application/json' }

      expect([400, 500]).to include(last_response.status)
      json = JSON.parse(last_response.body)
      expect(json['error']).to match(/Unknown action|generation failed/i)
    end

    it 'returns 400 for missing required fields' do
      payload = { action: 'send_email' }  # Missing 'data'

      post '/script/factory', payload.to_json, { 'CONTENT_TYPE' => 'application/json' }

      expect(last_response.status).to eq(400)
      json = JSON.parse(last_response.body)
      expect(json['error']).to eq('Validation failed')
    end
  end

  describe 'POST /at' do
    it 'schedules a task' do
      payload = { at: 'now', url: 'http://example.com/test' }

      post '/at', payload.to_json, { 'CONTENT_TYPE' => 'application/json' }

      expect(last_response.status).to eq(202)
      json = JSON.parse(last_response.body)
      expect(json['message']).to eq('Task scheduled')
      expect(json['task_id']).not_to be_nil
      expect(json['scheduled_at']).not_to be_nil
    end

    it 'returns 400 for invalid time format' do
      payload = { at: 'invalid time', url: 'http://example.com' }

      post '/at', payload.to_json, { 'CONTENT_TYPE' => 'application/json' }

      expect(last_response.status).to eq(400)
      json = JSON.parse(last_response.body)
      expect(json['error']).to eq('Invalid time format')
    end

    it 'returns error for invalid URL' do
      payload = { at: 'now', url: 'not a url' }

      post '/at', payload.to_json, { 'CONTENT_TYPE' => 'application/json' }

      expect(last_response.status).to be >= 400
      json = JSON.parse(last_response.body)
      expect(json['error']).not_to be_nil
    end

    it 'returns 400 for missing required fields' do
      payload = { at: 'now' }  # Missing 'url'

      post '/at', payload.to_json, { 'CONTENT_TYPE' => 'application/json' }

      expect(last_response.status).to eq(400)
      json = JSON.parse(last_response.body)
      expect(json['error']).to eq('Validation failed')
    end
  end

  describe 'GET /script/:id' do
    it 'returns 400 when script not found' do
      get '/script/nonexistent'

      expect(last_response.status).to eq(400)
      json = JSON.parse(last_response.body)
      expect(json['error']).to eq('Invalid argument')
    end
  end

  describe '404 handling' do
    it 'returns 404 for unknown routes' do
      get '/unknown/route'

      expect(last_response.status).to eq(404)
      json = JSON.parse(last_response.body)
      expect(json['error']).to eq('Not found')
      expect(json['path']).to eq('/unknown/route')
    end
  end

  describe 'error handling' do
    it 'does not expose internal error details' do
      # This would trigger an internal error
      allow_any_instance_of(ScriptEngine).to receive(:run).and_raise(StandardError, 'Internal error with sensitive info')

      script = { 'step1' => { 'command' => 'concatenate', 'data' => { 'string' => 'test' } } }
      post '/script/run', script.to_json, { 'CONTENT_TYPE' => 'application/json' }

      expect(last_response.status).to eq(500)
      json = JSON.parse(last_response.body)
      expect(json['message']).to eq('An unexpected error occurred')
      expect(json['message']).not_to include('sensitive info')
    end
  end
end
