require 'resque/tasks'
require 'resque_scheduler/tasks'

# The Rakefile is here entirely for Resque and Resque Scheduler's benefit. For
# all Aji tasks we should use Thor which sucks less.


# Load the Aji environment.
task :environment do
  puts "Loading Aji environment."
  require_relative 'aji'
end

namespace :resque do
  task :setup => :environment do
    Resque.after_fork do |job|
      ActiveRecord::Base.establish_connection Aji.conf['DATABASE']
    end

    # If your schedule already has +queue+ set for each job, you don't
    # need to require your jobs.  This can be an advantage since it's
    # less code that resque-scheduler needs to know about. But in a small
    # project, it's usually easier to just include you job classes here.
    # So, someting like this:
    # require_relative 'queues/*'

    # If you want to be able to dynamically change the schedule,
    # uncomment this line.  A dynamic schedule can be updated via the
    # Resque::Scheduler.set_schedule (and remove_schedule) methods.
    # When dynamic is set to true, the scheduler process looks for 
    # schedule changes and applies them on the fly.
    # Note: This feature is only available in >=2.0.0.
    #Resque::Scheduler.dynamic = true
  end
end

