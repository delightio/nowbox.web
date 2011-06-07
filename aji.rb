require 'rubygems'
require 'bundler'
Bundler.require

# This is the initilization file for the Kampanchi API. All set up, library
# loading and application level settings are done here.
module Aji
  def Aji.root; Dir.pwd; end

  # Set Rack environment if not specified.
  RACK_ENV = ENV['RACK_ENV'] || "development"

  # Load settings from configs or environment variables.
  # SETTINGS = YAML.load_file("./config/settings.yml")[RACK_ENV]
  ActiveRecord::Base.establish_connection(
    YAML.load_file("config/database.yml")[RACK_ENV])
  # Run all un-run migrations.
  ActiveRecord::Migrator.migrate("db/migrate/")
  s = YAML.load_file("config/redis.yml")[RACK_ENV]
  hash = Hash.new
  s.each { |k,v| hash[k.to_sym] = v }
  REDIS = Redis.new hash
  Redis::Objects.redis = REDIS

  class Error < RuntimeError; end
  class API < Grape::API
    get do
      "API Up and running!"
    end
  end
end

Dir.glob("models/*.rb").each { |r| require_relative r }
Dir.glob("helpers/*.rb").each { |r| require_relative r }
Dir.glob("controllers/*_controller.rb").each { |r| require_relative r }
