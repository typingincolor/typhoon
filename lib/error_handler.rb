# frozen_string_literal: true

require_relative 'errors'

# Generic error handler module for Sinatra applications
# Provides consistent error response formatting across all Typhoon errors
module Typhoon
  module ErrorHandler
    def self.included(base)
      base.class_eval do
        # Handle all Typhoon errors with consistent formatting
        error Typhoon::Error do |e|
          # Log server errors but not client errors
          LOGGER.error(e) if e.is_a?(Typhoon::ServerError)

          status e.status_code
          json e.to_h
        end

        # Fallback handler for unexpected errors
        error StandardError do |e|
          LOGGER.error("Unexpected error: #{e.class} - #{e.message}")
          LOGGER.error(e.backtrace.first(TyphoonConstants::Logging::BACKTRACE_LIMIT).join("\n"))

          status 500
          json error: 'Internal server error', message: 'An unexpected error occurred'
        end
      end
    end
  end
end
