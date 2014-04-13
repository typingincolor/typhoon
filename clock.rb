require 'stalker'

module Clockwork
  handler do |job|
    puts "Running #{job}"
    Stalker.enqueue job
  end

  every 60.seconds, 'run.tasks'
end
