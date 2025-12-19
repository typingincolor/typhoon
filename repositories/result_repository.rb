# frozen_string_literal: true

require 'json'
require_relative 'moneta_repository'

# Repository for managing task execution results
# Stores results as JSON with auto-incrementing IDs
class ResultRepository
  COUNTER_KEY = 'result_counter'

  def initialize(moneta_repo)
    @repo = moneta_repo
  end

  # Save a result and return its generated ID
  # @param result_data [Hash] The result data to store
  # @return [String] The generated result ID
  def save(result_data)
    result_id = generate_id
    @repo.save(result_id, result_data.to_json)
    result_id
  end

  # Find a result by ID
  # @param result_id [String] The result ID
  # @return [Hash, nil] The parsed result data or nil if not found
  def find(result_id)
    json = @repo.find(result_id)
    json ? JSON.parse(json) : nil
  end

  # Find a result by ID, raise error if not found
  # @param result_id [String] The result ID
  # @return [Hash] The parsed result data
  # @raise [ArgumentError] if result not found
  def find!(result_id)
    json = @repo.find!(result_id)
    JSON.parse(json)
  end

  # Delete a result by ID
  # @param result_id [String] The result ID
  # @return [void]
  def delete(result_id)
    @repo.delete(result_id)
  end

  private

  # Generate a new unique result ID
  # @return [String] The generated ID
  def generate_id
    @repo.increment_counter(COUNTER_KEY).to_s
  end
end
