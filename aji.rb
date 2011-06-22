require 'rubygems'
require 'bundler'
Bundler.require

# This is the initilization file for the Aji API. All set up, library
# loading and application level settings are done here.
module Aji
  def Aji.root; Dir.pwd; end

  # Set Rack environment if not specified.
  RACK_ENV = ENV['RACK_ENV'] || "development"

  def Aji.conf
    @conf_hash ||= YAML.load_file("config/settings.yml")[RACK_ENV].merge ENV
  end
  BASE_URL = Aji.conf['BASE_URL'] || 'localhost'

  # Establish Redis connection.
  redis_url = Aji.conf['REDISTOGO_URL']
  REDIS = Redis.connect :url=>redis_url
  Resque.redis = REDIS
  Redis::Objects.redis = REDIS
  Resque.schedule = YAML.load_file 'config/resque_schedule.yml'

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
    namespace '1' do
      get do
        "API Version 1 up and running!"
      end
    end
  end
end

Dir.glob("models/*.rb").each { |r| require_relative r }
# Must load channel subtypes after other models for dependency reasons.
Dir.glob("models/channels/*.rb").each { |r| require_relative r }
Dir.glob("models/external_accounts/*.rb").each { |r| require_relative r }
Dir.glob("helpers/*.rb").each { |r| require_relative r }
Dir.glob("controllers/*_controller.rb").each { |r| require_relative r }
Dir.glob("queues/*.rb").each { |r| require_relative r }

# Add Sinatra web viewer.
require_relative "lib/viewer/viewer.rb"
