require 'pry'
require './aji'

def replay_events
  @events.each do |e|
    e.send :process
  end
  nil
end

until @timecode.kind_of? Time
  print "#{@timecode.inspect} is an invalid timecode, please try again.\n"
  print "Pick a time to start at >"
  @timecode = eval(gets)
end

@events = Aji::Event.where(:created_at => @timecode..Time.now)


puts "There have been #{@events.size} since #{@timecode.inspect}",
  "enter `replay_events` to process all of them again.",
  "or just play around with the @events variable."

Pry.start

