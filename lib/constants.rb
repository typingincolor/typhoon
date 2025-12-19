# frozen_string_literal: true

# Global constants for the Typhoon application
# Extracted to eliminate magic numbers and improve maintainability
module TyphoonConstants
  # HTTP client configuration
  module HTTP
    # Timeout for HTTP requests in seconds
    TIMEOUT_SECONDS = 30
  end

  # Logging configuration
  module Logging
    # Number of backtrace lines to include in error logs
    BACKTRACE_LIMIT = 5
  end
end
