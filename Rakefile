require 'resque/tasks'
require 'resque_scheduler/tasks'

# The Rakefile is here entirely for Resque and Resque Scheduler's benefit. For
# all Aji tasks we should use Thor which sucks less.
task :c => :console


# Load the Aji environment.
task :environment do
  puts "Loading Aji environment."
  require_relative 'aji'
end

task :console => :environment do
  Bundler.require :development
  Pry.start Aji
end

task :readstream => :environment do
  require_relative 'lib/read_stream'
end

namespace :resque do
  task :setup => :environment
end

