ENV['RACK_ENV'] = 'test'

require_relative '../../aji'
require 'rspec'
require 'rack/test'
require 'database_cleaner'
require 'vcr'

VCR.configure do |c|
  c.cassette_library_dir = "features/support/cassettes"
  c.hook_into :webmock
  c.default_cassette_options = { :record => :new_episodes }
end


def app
  Aji::APP
end

Spinach::FeatureSteps.send :include, Rack::Test::Methods

Spinach.hooks.before_feature do
  DatabaseCleaner.start
  Aji.redis.flushdb
end

Spinach.hooks.after_feature do
  DatabaseCleaner.clean
end

