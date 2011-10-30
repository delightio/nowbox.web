ENV['RACK_ENV'] = 'test'

require_relative '../../aji'
require 'rspec'
require 'rack/test'
require 'vcr'

VCR.configure do |c|
  c.cassette_library_dir = "features/support/cassettes"
  c.hook_into :typhoeus
  c.default_cassette_options = { :record => :none }
end


def app
  Aji::APP
end

Spinach::FeatureSteps.send :include, Rack::Test::Methods

