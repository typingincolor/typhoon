require 'sidekiq'
require 'sidekiq-scheduler'
require 'http'
require 'moneta'
require_relative '../config/config'
require_relative '../config/logger'
require_relative '../config/database'
require_relative '../lib/constants'
require_relative '../repositories/moneta_repository'
require_relative '../repositories/result_repository'

class TaskExecutorWorker
  include Sidekiq::Worker

  sidekiq_options retry: 3, dead: true

  def perform
    LOGGER.info('Checking for pending tasks')

    tasks = Task.pending
    LOGGER.info("Found #{tasks.count} pending tasks")

    return if tasks.empty?

    # Setup result repository
    result_repository = build_result_repository

    tasks.each do |task|
      execute_task(task, result_repository)
    end
  end

  private

  def build_result_repository
    moneta_store = Moneta.new(:File, dir: Config.moneta[:results_dir])
    moneta_repo = MonetaRepository.new(moneta_store)
    ResultRepository.new(moneta_repo)
  end

  def execute_task(task, result_repository)
    LOGGER.info("Executing task #{task.id}: #{task.url}")

    response = HTTP.timeout(TyphoonConstants::HTTP::TIMEOUT_SECONDS).get(task.url)
    response_code = response.code

    # Store result using repository
    result_id = result_repository.save(
      task_id: task.id,
      url: task.url,
      status: response_code,
      body: response.body.to_s,
      executed_at: Time.now.utc.iso8601
    )

    # Mark task as completed
    task.mark_completed!(response_code: response_code, result_id: result_id)

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
