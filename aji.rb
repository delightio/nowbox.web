require 'rubygems'
require 'bundler'
Bundler.require

# This is the initilization file for the Aji API. All set up, library
# loading and application level settings are done here.
module Aji
  # Set the application root directory.
  def Aji.root; File.expand_path('..', __FILE__); end

  # Simple logging interface for local development and heroku. May grow in
  # complexity later, hence methodizing it.
  def Aji.log message; puts message; end

  # Set Rack environment if not specified.
  RACK_ENV = ENV['RACK_ENV'] || "development"

  # Accessor for the configuration hash. If none has been created a new hash is
  # yielded. This hash is made immutable at the end of `config/setup.rb`.
  def Aji.conf; @conf_hash ||= Hash.new; end

  # Handles initialization and preprocessing of application settings be they
  # from Heroku's Environment or a local `settings.yml`.
  require_relative 'config/setup.rb'

  # Establish Redis connection and initialize Redis-backed utilities.
  def Aji.redis; @redis ||= Redis.new conf['REDIS']; end
  Resque.redis = redis
  Redis::Objects.redis = redis
  Resque.schedule = conf['RESQUE_SCHEDULE']

  # Establish ActiveRecord conneciton and run all necessary migrations.
  ActiveRecord::Base.establish_connection conf['DATABASE']
  ActiveRecord::Migrator.migrate("db/migrate/")

  # An application specific error class.
  class Error < RuntimeError; end
  # An error to raise when a required interface method has not been overridden
  # by a subclass.
  class InterfaceMethodNotImplemented < Aji::Error; end

  class API < Grape::API
    version '1'
    get do
      "API Version 1 up and running!"
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
Dir.glob("queues/mention/*.rb").each { |r| require_relative r }

# Add Sinatra web viewer.
require_relative "lib/viewer/viewer.rb"

# Add miscelaneous library code.
module Parsers; end
Dir.glob("lib/parsers/*.rb").each { |r| require_relative r }

