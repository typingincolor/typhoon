# frozen_string_literal: true

# Unified error hierarchy for Typhoon application
# Provides consistent error handling with proper HTTP status codes and structured responses
module Typhoon
  # Base error class for all Typhoon-specific errors
  # Includes status code, error type, and structured output
  class Error < StandardError
    attr_reader :details

    def initialize(message, details: nil)
      super(message)
      @details = details
    end

    # HTTP status code for this error type
    def status_code
      500 # Default to internal server error
    end

    # Human-readable error type
    def error_type
      self.class.name.split('::').last.gsub(/([A-Z])/, ' \1').strip
    end

    # Convert error to hash for JSON responses
    def to_h
      {
        error: error_type,
        message: message,
        details: details
      }.compact
    end
  end

  # Base class for 4xx client errors
  class ClientError < Error
    def status_code
      400
    end
  end

  # 422 Unprocessable Entity - Validation failures
  class ValidationError < ClientError
    def initialize(message, errors: nil)
      super(message, details: errors)
    end

    def status_code
      422
    end

    def error_type
      'Validation failed'
    end
  end

  # 400 Bad Request - Invalid JSON
  class InvalidJSONError < ClientError
    def error_type
      'Invalid JSON'
    end
  end

  # 404 Not Found - Resource doesn't exist
  class ResourceNotFoundError < ClientError
    def status_code
      404
    end

    def error_type
      'Not found'
    end
  end

  # 400 Bad Request - Unknown action specified
  class UnknownActionError < ClientError
    def error_type
      'Unknown action'
    end
  end

  # Base class for 5xx server errors
  class ServerError < Error
    def status_code
      500
    end

    def error_type
      'Internal server error'
    end
  end

  # 422 Unprocessable Entity - Script execution failure
  class ScriptExecutionError < ServerError
    def status_code
      422
    end

    def error_type
      'Script execution failed'
    end
  end

  # 500 Internal Server Error - Script generation failure
  class ScriptGenerationError < ServerError
    def error_type
      'Script generation failed'
    end
  end
end
