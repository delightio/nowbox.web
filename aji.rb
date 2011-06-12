require 'rubygems'
require 'bundler'
Bundler.require

# This is the initilization file for the Kampanchi API. All set up, library
# loading and application level settings are done here.
module Aji
  def Aji.root; Dir.pwd; end

  # Set Rack environment if not specified.
  RACK_ENV = ENV['RACK_ENV'] || "development"

  def Aji.conf key
    ENV[key] || YAML.load_file("config/settings.yml")[RACK_ENV][key]
  end
  BASE_URI = Aji.conf('BASE_URL') || 'localhost'
  
  # Establish Redis connection.
  redis_url = ENV["REDISTOGO_URL"] || YAML.load_file("config/redis.yml")[RACK_ENV]["REDISTOGO_URL"]
  REDIS = Redis.connect :url=>redis_url
  Redis::Objects.redis = REDIS
  
  # Load settings from configs or environment variables.
  # SETTINGS = YAML.load_file("./config/settings.yml")[RACK_ENV]
  
  # Establish ActiveRecord conneciton and run all necessary migration
  
  puts "Trying to establish AR connection..."
  puts "DATABASE_URL: #{ENV['DATABASE_URL']}"
  puts "Trying to load config/database.yml"
  puts " content:"
  f = File.open 'config/database.yml'
  f.each_line {|line| puts line }
  puts "--"
  ActiveRecord::Base.establish_connection YAML.load_file('config/database.yml')[RACK_ENV]
  ActiveRecord::Migrator.migrate("db/migrate/")
  
  # An application specific error class.
  class Error < RuntimeError; end
  # An error to raise when a required interface method has not been overridden
  # by a subclass.
  class InterfaceMethodNotImplemented < Aji::Error; end
  class API < Grape::API
    get do
      "API Up and running!"
    end
  end
end

Dir.glob("models/*.rb").each { |r| require_relative r }
# Must load channel subtypes after other models for dependency reasons.
Dir.glob("models/channels/*.rb").each { |r| require_relative r }
Dir.glob("models/external_accounts/*.rb").each { |r| require_relative r }
Dir.glob("helpers/*.rb").each { |r| require_relative r }
Dir.glob("controllers/*_controller.rb").each { |r| require_relative r }
