ENV['RACK_ENV'] = 'test'

require_relative '../../aji'
require 'rspec'
require 'rack/test'

def app
  Aji::APP
end

Spinach::FeatureSteps.send :include, Rack::Test::Methods

