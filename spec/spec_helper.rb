ENV["RACK_ENV"] ||= 'test'
require 'bundler'
Bundler.require :test
require './spec/factories'
require './features/support/omniauth_hashes'

SimpleCov.start

require './aji'

VCR.configure do |c|
  c.cassette_library_dir = "spec/support/cassettes"
  c.hook_into :webmock
  c.default_cassette_options = {
    :record => :new_episodes, :re_record_interval => 1.month }
    c.allow_http_connections_when_no_cassette = true
end

module TestMixin
  include Rack::Test::Methods
  def app
    Aji::APP
  end

  def host
    "api.#{Aji.conf['TLD']}"
  end

  def build_rack_mock_session
    Rack::MockSession.new app, host
  end
end

RSpec.configure do |config|
  config.treat_symbols_as_metadata_keys_with_true_values = true
  config.mock_with :rspec
  config.include TestMixin

  config.before :each do
    DatabaseCleaner.start
    Aji.redis.flushdb
  end

  config.after :each do
    DatabaseCleaner.clean
  end
end

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir.glob("#{Aji.root}/spec/support/**/*.rb").each {|r| require_relative r}
