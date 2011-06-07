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

  s = YAML.load_file("config/redis.yml")
  h = Hash.new
  s.each { |k,v| h[k.to_sym] = v }
  def Aji.redis
    @@redis ||= Redis.new(h)
  end

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
