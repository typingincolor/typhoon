# frozen_string_literal: true

require_relative '../config/logger'
require_relative '../lib/errors'

# Repository pattern wrapper for Moneta store
# Provides consistent API and centralizes storage operations
class MonetaRepository
  def initialize(store)
    @store = store
  end

  # Save a value with the given key
  # @param key [String] Storage key
  # @param value [Object] Value to store
  # @return [String] The key
  def save(key, value)
    @store[key] = value
    LOGGER.debug("Stored item with key: #{key}")
    key
  end

  # Find a value by key
  # @param key [String] Storage key
  # @return [Object, nil] The stored value or nil if not found
  def find(key)
    @store[key]
  end

  # Find a value by key, raise error if not found
  # @param key [String] Storage key
  # @return [Object] The stored value
  # @raise [Typhoon::ResourceNotFoundError] if key not found
  def find!(key)
    value = find(key)
    raise Typhoon::ResourceNotFoundError, "Resource with key '#{key}' not found" unless value

    value
  end

  # Delete a value by key
  # @param key [String] Storage key
  # @return [void]
  def delete(key)
    @store.delete(key)
  end

  # Check if a key exists
  # @param key [String] Storage key
  # @return [Boolean] true if key exists
  def exists?(key)
    @store.key?(key)
  end

  # Increment a counter and return the new value
  # @param counter_name [String] Name of the counter
  # @return [Integer] The incremented value
  def increment_counter(counter_name)
    @store.increment(counter_name)
  end
end
