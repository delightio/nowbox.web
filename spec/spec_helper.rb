ENV["RACK_ENV"] ||= 'test'
Bundler.require :test


SimpleCov.start

require 'rspec'
require 'rack/test'
require_relative '../aji'
require_relative 'factories'

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir.glob("#{Aji.root}/spec/support/**/*.rb").each {|r| require_relative r}

module TestMixin
  include Rack::Test::Methods
  def app
    Aji::API
  end
end

EphemeralResponse.configure do |config|
  config.fixture_directory = "spec/fixtures/ephemeral_response"
  config.expiration = 604800 # 7 days.
end

RSpec.configure do |config|
  # == Mock Framework
  #
  # If you prefer to use mocha, flexmock or RR, uncomment the appropriate line:
  #
  # config.mock_with :flexmock
  # config.mock_with :mocha
  # config.mock_with :rr
  config.mock_with :rspec

  # Use ephemeral response for HTTP caching.
  config.before(:suite){ EphemeralResponse.activate }
  config.before(:suite){ EphemeralResponse.deactivate }

  config.include TestMixin
  config.include Factory::Syntax::Methods

  config.before(:each) do
    Aji.redis.flushdb
    [Aji::User, Aji::Channel, Aji::Event, Aji::ExternalAccount,
      Aji::Video].map{|c| c.all.each{|obj| obj.delete} }
  end
end
