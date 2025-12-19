require 'logger'
require 'oj'
require_relative '../lib/constants'

module TyphoonLogger
  class JSONFormatter < Logger::Formatter
    def call(severity, time, progname, msg)
      log_entry = {
        'timestamp' => time.utc.iso8601,
        'severity' => severity,
        'message' => msg.is_a?(String) ? msg : msg.inspect,
        'progname' => progname
      }

      # Add exception details if present
      if msg.is_a?(Exception)
        log_entry['exception'] = {
          'class' => msg.class.name,
          'message' => msg.message,
          'backtrace' => msg.backtrace&.first(TyphoonConstants::Logging::BACKTRACE_LIMIT)
        }
      end

      Oj.dump(log_entry) + "\n"
    end
  end

  def self.create(output = $stdout)
    logger = Logger.new(output)
    logger.level = ENV['LOG_LEVEL']&.upcase == 'DEBUG' ? Logger::DEBUG : Logger::INFO
    logger.formatter = JSONFormatter.new
    logger
  end
end

# Global logger instance
LOGGER = TyphoonLogger.create
