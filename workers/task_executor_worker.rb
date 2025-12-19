require 'sidekiq'
require 'http'
require_relative '../config/config'
require_relative '../config/logger'
require_relative '../config/database'
require_relative '../lib/constants'

class TaskExecutorWorker
  include Sidekiq::Worker

  sidekiq_options retry: 3, dead: true

  def perform
    LOGGER.info('Checking for pending tasks')

    tasks = Task.pending
    LOGGER.info("Found #{tasks.count} pending tasks")

    return if tasks.empty?

    # Setup results store
    results_store = Moneta.new(:File, dir: Config.moneta[:results_dir])

    tasks.each do |task|
      execute_task(task, results_store)
    end
  end

  private

  def execute_task(task, results_store)
    LOGGER.info("Executing task #{task.id}: #{task.url}")

    response = HTTP.timeout(TyphoonConstants::HTTP::TIMEOUT_SECONDS).get(task.url)
    response_code = response.code

    # Store result
    counter = results_store.increment('results').to_s
    results_store[counter] = {
      task_id: task.id,
      url: task.url,
      status: response_code,
      body: response.body.to_s,
      executed_at: Time.now.utc.iso8601
    }.to_json

    # Mark task as completed
    task.mark_completed!(response_code: response_code, result_id: counter)

    LOGGER.info("Task #{task.id} completed with status #{response_code}")
  rescue HTTP::Error, Errno::ECONNREFUSED => e
    LOGGER.error("HTTP error executing task #{task.id}: #{e.message}")
    raise # Let Sidekiq handle retry
  rescue => e
    LOGGER.error("Unexpected error executing task #{task.id}: #{e.message}")
    LOGGER.error(e.backtrace.first(TyphoonConstants::Logging::BACKTRACE_LIMIT).join("\n"))
    raise
  end
end
