require 'bundler'

# Must be required before NewRelic Agent (in Bundler.require)
Bundler.require
require_relative 'lib/rpm_contrib/instrumentation/grape'
#Grape::Endpoint.class_eval do
#  include RPMContrib::Instrumentation::Grape
#
#  alias call_without_newrelic call
#  alias call call_with_newrelic
#end

Faraday.default_adapter = :typhoeus

# This is the initilization file for the Aji API. All set up, library
# loading and application level settings are done here.
module Aji
  # Set the application root directory.
  def Aji.root
    File.expand_path('..', __FILE__)
  end

  # Logging interface for local development and heroku.
  # There are four internal Log levels aliased to the standard SYSLOG levels.
  # The INFO level is used if no level is specified. Other options are `:DEBUG`,
  # for DEBUG and `:WARN`, `:FATAL`, `:ERROR` for ERROR as well as a `:WTF`
  # option for Really Bad Things. downcased versions of these work as well.
  # DEBUG logs are not logged in production environments so conditional logging
  # should not be used.
  def Aji.log level=:INFO, message
    return if RACK_ENV == 'test' unless ENV['LOG']

    case level
    when :ERROR, :WARN, :FATAL, :error, :warn, :fatal
      $stderr.puts message
    when :DEBUG, :debug
      return if RACK_ENV == 'production'
      $stdout.puts '----------DEBUG----------', message,
        '----------DEBUG----------'
    when :WTF, :wtf
      $stderr.puts "!!!!!!!!!!!!!!!!!!!! LOOOK AT ME DAMMIT !!!!!!!!!!!!!!!!!!!!",
           "!!!!!!!!!!!!!!!!!!!! I AM NOT RIGHT MAN !!!!!!!!!!!!!!!!!!!!",
           message,
           "!!!!!!!!!!!!!!!!!!!!   FOR FUCK'S SAKE   !!!!!!!!!!!!!!!!!!!",
           "!!!!!!!!!!!!!!!!!!!! JUST LOOK UP PLEASE !!!!!!!!!!!!!!!!!!!"
    else
      $stdout.puts message
    end
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
  def Aji.redis
    @redis ||= Redis.new conf['REDIS']
  end

  Resque.redis = redis
  Redis::Objects.redis = redis
  Resque.schedule = conf['RESQUE_SCHEDULE']
  Resque.before_fork = proc { ActiveRecord::Base.establish_connection(
    Aji.conf['DATABASE']) }
  Resque::Failure::MultipleWithRetrySuppression.classes =
    [Resque::Failure::Redis]
  Resque::Failure.backend = Resque::Failure::MultipleWithRetrySuppression

  # Establish ActiveRecord conneciton and run all necessary migrations.
  ActiveRecord::Base.establish_connection conf['DATABASE']
  ActiveRecord::Base.default_timezone = :utc

  # For Account and Channel search
  Tanker.configuration = { :url => Aji.conf['INDEXTANK_API_URL'] }

  # An application specific error class.
  class Error < RuntimeError; end
  # An error to raise when a required interface method has not been overridden
  # by a subclass.
  class InterfaceMethodNotImplemented < Aji::Error; end

  Grape.send :include, RPMContrib::Instrumentation::Grape

  class API < Grape::API
    version '1'
  end
end

require 'active_support/core_ext/object'
# Monkey Patching
require_relative 'lib/patches/string'
require_relative 'lib/patches/youtube_it/client'
require_relative 'lib/patches/youtube_it/request/video_upload'

Aji::Mixins = Module.new
Dir.glob("lib/mixins/*.rb").each { |r| require_relative r }
require_relative 'lib/tanker_defaults'
require_relative 'lib/decay'
require_relative 'lib/parsers'
require_relative 'lib/searcher'
require_relative 'lib/info'

Dir.glob("models/*.rb").each { |r| require_relative r }
# Must load channel subtypes after other models for dependency reasons.
Dir.glob("models/channel/*.rb").each { |r| require_relative r }
Dir.glob("models/account/*.rb").each { |r| require_relative r }

Dir.glob("helpers/*.rb").each { |r| require_relative r }
Dir.glob("controllers/*_controller.rb").each { |r| require_relative r }
require_relative 'queues/with_database_connection.rb'
Dir.glob("queues/*.rb").each { |r| require_relative r }
Dir.glob("queues/mention/*.rb").each { |r| require_relative r }
Dir.glob("queues/debug/*.rb").each { |r| require_relative r }

# Add Sinatra web viewer.
require_relative 'lib/google_auth'
require_relative 'lib/viewer/viewer'
require_relative 'lib/mailer/mailer'

require_relative 'app'
