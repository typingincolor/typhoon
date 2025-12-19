# frozen_string_literal: true

require_relative 'moneta_repository'

# Repository for managing script storage
# Handles script persistence with auto-incrementing IDs
class ScriptRepository
  COUNTER_KEY = 'script_counter'

  def initialize(moneta_repo)
    @repo = moneta_repo
  end

  # Save a script and return its generated ID
  # @param script [String] The script content to store
  # @return [String] The generated script ID
  def save(script)
    script_id = generate_id
    @repo.save(script_id, script)
    script_id
  end

  # Find a script by ID
  # @param script_id [String] The script ID
  # @return [String, nil] The script content or nil if not found
  def find(script_id)
    @repo.find(script_id)
  end

  # Find a script by ID, raise error if not found
  # @param script_id [String] The script ID
  # @return [String] The script content
  # @raise [ArgumentError] if script not found
  def find!(script_id)
    @repo.find!(script_id)
  end

  # Delete a script by ID
  # @param script_id [String] The script ID
  # @return [void]
  def delete(script_id)
    @repo.delete(script_id)
  end

  private

  # Generate a new unique script ID
  # @return [String] The generated ID
  def generate_id
    @repo.increment_counter(COUNTER_KEY).to_s
  end
end
