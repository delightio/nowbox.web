require 'resque/tasks'
require 'resque_scheduler/tasks'

unless ENV['RACK_ENV'] == 'production'
  require 'rspec/core/rake_task'
  RSpec::Core::RakeTask.new(:spec)
end

# Load the Aji environment.
task :environment do
  puts "Loading Aji environment."
  require_relative 'aji'
end

task :c => :console
task :console => :environment do
  Pry.config.print = proc { |output, value| output.puts value.ai }
  Pry.start Aji
end

task :readstream => :environment do
  require_relative 'lib/read_stream'
end

namespace :resque do
  task :setup => :environment
end

task :default => :spec
