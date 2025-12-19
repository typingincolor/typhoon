require_relative '../spec_helper'
require_relative '../../workers/task_executor_worker'
require 'moneta'

RSpec.describe TaskExecutorWorker do
  let(:worker) { TaskExecutorWorker.new }

  before do
    # Stub Config.moneta for tests
    allow(Config).to receive(:moneta).and_return({ results_dir: 'moneta_results_test' })
  end

  after do
    # Clean up test moneta directory
    FileUtils.rm_rf('moneta_results_test') if Dir.exist?('moneta_results_test')
  end

  describe '#perform' do
    it 'processes no tasks when none are pending' do
      Task.create(url: 'http://example.com', at: Time.now + 3600)

      expect { worker.perform }.not_to raise_error
    end

    it 'executes pending tasks' do
      task = Task.create(url: 'http://example.com/test', at: Time.now - 60)

      stub_request(:get, 'http://example.com/test')
        .to_return(status: 200, body: 'Success')

      worker.perform

      task.reload
      expect(task.completed?).to be true
      expect(task.code).to eq(200)
    end

    it 'marks multiple pending tasks as completed' do
      task1 = Task.create(url: 'http://example.com/1', at: Time.now - 60)
      task2 = Task.create(url: 'http://example.com/2', at: Time.now - 30)

      stub_request(:get, 'http://example.com/1').to_return(status: 200)
      stub_request(:get, 'http://example.com/2').to_return(status: 200)

      worker.perform

      expect(task1.reload.completed?).to be true
      expect(task2.reload.completed?).to be true
    end

    it 'does not process future tasks' do
      future_task = Task.create(url: 'http://example.com', at: Time.now + 3600)

      worker.perform

      expect(future_task.reload.completed?).to be false
    end

    it 'does not reprocess already completed tasks' do
      task = Task.create(
        url: 'http://example.com',
        at: Time.now - 60,
        completed_at: Time.now,
        code: 200
      )

      worker.perform

      # Should not make HTTP request
      expect(WebMock).not_to have_requested(:get, 'http://example.com')
    end

    it 'stores result in Moneta' do
      task = Task.create(url: 'http://example.com', at: Time.now - 60)

      stub_request(:get, 'http://example.com')
        .to_return(status: 200, body: 'Response body')

      worker.perform

      task.reload
      expect(task.result).not_to be_nil
      expect(task.result).to match(/^\d+$/)
    end

    it 'handles HTTP errors with retry' do
      task = Task.create(url: 'http://example.com', at: Time.now - 60)

      stub_request(:get, 'http://example.com')
        .to_raise(HTTP::ConnectionError)

      expect { worker.perform }.to raise_error(HTTP::ConnectionError)

      task.reload
      expect(task.completed?).to be false
    end

    it 'handles connection refused' do
      task = Task.create(url: 'http://example.com', at: Time.now - 60)

      stub_request(:get, 'http://example.com')
        .to_raise(Errno::ECONNREFUSED)

      expect { worker.perform }.to raise_error(Errno::ECONNREFUSED)
    end
  end
end
