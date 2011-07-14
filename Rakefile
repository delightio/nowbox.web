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
  end
end

