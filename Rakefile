require 'resque/tasks'
require 'resque_scheduler/tasks'

unless ENV['RACK_ENV'] == 'production'
  require 'rspec/core/rake_task'
  RSpec::Core::RakeTask.new(:spec)
end

namespace :spec do
  task :unit do
    system %(bin/rspec spec -t unit)
  end
end

def source_dirs
  %w[models queues lib controllers config helpers]
end

def source_files
  Dir.glob("{#{source_dirs * ','}}/**/*.rb")
end

# Load the Aji environment.
task :environment do
  puts "Loading Aji #{ENV['RACK_ENV']} environment."
  require_relative 'aji'
end

task :c => :console
task :console => :environment do
  Pry.config.print = proc { |output, value| output.puts value.ai }
  Pry.start Aji
end

task :h => :heroku_console
task :heroku_console do
  system "heroku run console --app aji"
end

task :s => :staging_console
task :staging_console do
  system "heroku run console --app aji-staging"
end

task :cc => :client_console
task :client_console do
  system "ruby script/client_console.rb"
end

task :flog do
  sh %(flog --continue #{source_files * ' '})
end

task :flay do
  sh %(flay #{source_files * ' '})
end

namespace :resque do
  task :setup => :environment
end

namespace :db do
  task :migrate => :environment do
    ActiveRecord::Migrator.migrate("db/migrate/")
  end
end

task :default => :spec
