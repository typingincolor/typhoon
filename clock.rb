require 'stalker'

module Clockwork
  handler do |job|
    puts "Running #{job}"
    Stalker.enqueue job
  end

  every 1.minute, 'run.tasks'
end
