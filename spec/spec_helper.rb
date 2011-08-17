ENV["RACK_ENV"] ||= 'test'
require 'bundler'
Bundler.require :test


SimpleCov.start
require_relative '../aji'
require_relative 'factories'

#VCR.config do |c|
#  c.cassette_library_dir = "fixtures/vcr_cassettes"
#  c.stub_with :fakeweb
#  c.default_cassette_options = { :record => :new_episodes }
#end

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir.glob("#{Aji.root}/spec/support/**/*.rb").each {|r| require_relative r}

module TestMixin
  include Rack::Test::Methods
  def app
    Aji::API
  end
end

RSpec.configure do |config|
  # == Mock Framework
  #
  # If you prefer to use mocha, flexmock or RR, uncomment the appropriate line:
  #
  # config.mock_with :mocha
  # config.mock_with :flexmock
  # config.mock_with :rr
  config.mock_with :rspec
  config.include TestMixin
  # config.extend VCR::RSpec::Macros
#  config.before :suite do
#    DatabaseCleaner.strategy = :transaction
#    DatabaseCleaner.clean_with(:truncation)
#  end

  config.before :each do
    DatabaseCleaner.start
    Aji.redis.flushdb
  end

  config.after :each do
    DatabaseCleaner.clean
  end
end
