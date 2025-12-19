require_relative 'config'

# Puma configuration
port Config.app[:port]
environment Config.env

# Worker processes
workers Integer(ENV.fetch('WEB_CONCURRENCY', 2))

# Threads per worker
threads_count = Integer(ENV.fetch('MAX_THREADS', 5))
threads threads_count, threads_count

# Preload application for better performance
preload_app!

# Allow puma to be restarted by `rails restart` command.
plugin :tmp_restart

on_worker_boot do
  require_relative 'database'
end
