require 'rubygems'
require 'bundler'
Bundler.require

# This is the initilization file for the Aji API. All set up, library
# loading and application level settings are done here.
module Aji
  def Aji.root; Dir.pwd; end

  # Set Rack environment if not specified.
  RACK_ENV = ENV['RACK_ENV'] || "development"

  def Aji.conf key, setting_yml='config/settings.yml'
    ENV[key] || YAML.load_file(setting_yml)[RACK_ENV][key]
  end
  BASE_URL = Aji.conf('BASE_URL') || 'localhost'

  # Establish Redis connection.
  redis_url = Aji.conf 'REDISTOGO_URL'
  REDIS = Redis.connect :url=>redis_url
  Redis::Objects.redis = REDIS

  # HACK: Heroku returns a ERB version of config/database.yml.
  # I had to manually do the following for deployment.
  if ENV['DATABASE_URL']
    uri = URI.parse ENV['DATABASE_URL']
    adapter = uri.scheme
    adapter = "postgresql" if adapter == "postgres"
    database = (uri.path || "").split("/")[1]
    dbconfig = { :adapter => adapter,
                 :database => database,
                 :host => uri.host,
                 :port => uri.port,
                 :username => uri.user,
                 :password => uri.password,
                 :params => CGI.parse(uri.query || "") }
  else
    dbconfig = YAML.load_file('config/database.yml')[RACK_ENV]
  end
  # Establish ActiveRecord conneciton and run all necessary migration
  ActiveRecord::Base.establish_connection dbconfig
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

# HACK: % heroku config => shows Ruby 1.9.1
# The deployed app actually works as expected. However, %heroku run console
# does not know anything about Aji::* objects.

# Dir.glob("models/*.rb").each { |r| require_relative r }
# # Must load channel subtypes after other models for dependency reasons.
# Dir.glob("models/channels/*.rb").each { |r| require_relative r }
# Dir.glob("models/external_accounts/*.rb").each { |r| require_relative r }
# Dir.glob("helpers/*.rb").each { |r| require_relative r }
# Dir.glob("controllers/*_controller.rb").each { |r| require_relative r }

Dir.glob("models/*.rb").each { |r| require "#{Aji.root}/#{r}" }
# Must load channel subtypes after other models for dependency reasons.
Dir.glob("models/channels/*.rb").each { |r| require "#{Aji.root}/#{r}" }
Dir.glob("models/external_accounts/*.rb").each { |r| require "#{Aji.root}/#{r}" }
Dir.glob("helpers/*.rb").each { |r| require "#{Aji.root}/#{r}" }
Dir.glob("controllers/*_controller.rb").each { |r| require "#{Aji.root}/#{r}" }

Dir.glob("queues/*.rb").each { |r| require "#{Aji.root}/#{r}" }

