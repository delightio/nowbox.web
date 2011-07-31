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
  def Aji.log level=:INFO, message
    case level
    when :ERROR, :WARN, :FATAL, :error, :warn, :fatal
      $stderr.puts message
    when :DEBUG, :debug
      $stdout.puts '----------DEBUG----------', message,
        '----------DEBUG----------'
    when :WTF, :wtf
      puts "!!!!!!!!!!!!!!!!!!!! LOOOK AT ME DAMMIT !!!!!!!!!!!!!!!!!!!!",
           "!!!!!!!!!!!!!!!!!!!! I AM NOT RIGHT MAN !!!!!!!!!!!!!!!!!!!!",
           message,
           "!!!!!!!!!!!!!!!!!!!!   FOR FUCK'S SAKE   !!!!!!!!!!!!!!!!!!!",
           "!!!!!!!!!!!!!!!!!!!! JUST LOOK UP PLEASE !!!!!!!!!!!!!!!!!!!"
    else
      $stdout.puts message
    end
  end

  def Aji.youtube_client
    @youtube_client ||= YouTubeIt::Client.new
  end

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

module Mixins; end # Since models need them
Dir.glob("lib/mixins/*.rb").each { |r| require_relative r }

Dir.glob("models/*.rb").each { |r| require_relative r }
# Must load channel subtypes after other models for dependency reasons.
Dir.glob("models/channels/*.rb").each { |r| require_relative r }
Dir.glob("models/external_accounts/*.rb").each { |r| require_relative r }

# Run migrations after models are loaded.
ActiveRecord::Migrator.migrate("db/migrate/")

Dir.glob("helpers/*.rb").each { |r| require_relative r }
Dir.glob("controllers/*_controller.rb").each { |r| require_relative r }
Dir.glob("queues/*.rb").each { |r| require_relative r }
Dir.glob("queues/mention/*.rb").each { |r| require_relative r }

# Add Sinatra web viewer.
require_relative "lib/viewer/viewer"

# Add miscelaneous library code.
# Dir.glob("lib/*.rb").each { |r| require_relative r }
require_relative 'lib/decay'
require_relative 'lib/macker'

module Parsers; end
Dir.glob("lib/parsers/*.rb").each { |r| require_relative r }

