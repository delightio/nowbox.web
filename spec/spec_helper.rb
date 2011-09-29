require 'spork'

Spork.prefork do
  # Loading more in this block will cause your tests to run faster. However, 
  # if you change any configuration or code from libraries loaded here, you'll
  # need to restart spork for it take effect.
  ENV["RACK_ENV"] ||= 'test'
  require 'bundler'
  Bundler.require :test
  require './spec/factories'

  SimpleCov.start

  require './aji'

  VCR.config do |c|
    c.cassette_library_dir = "spec/cassettes"
    c.stub_with :typhoeus
    c.default_cassette_options = { :record => :none }
  end

  module TestMixin
    include Rack::Test::Methods
    def app
      Aji::API
    end
  end

  RSpec.configure do |config|
    config.treat_symbols_as_metadata_keys_with_true_values = true
    config.mock_with :rspec
    config.include TestMixin
    config.extend VCR::RSpec::Macros
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
end

Spork.each_run do
  # This code will be run each time you run your specs.

end

# --- Instructions ---
# - Sort through your spec_helper file. Place as much environment loading 
#   code that you don't normally modify during development in the 
#   Spork.prefork block.
# - Place the rest under Spork.each_run block
# - Any code that is left outside of the blocks will be ran during preforking
#   and during each_run!
# - These instructions should self-destruct in 10 seconds.  If they don't,
#   feel free to delete them.
#
