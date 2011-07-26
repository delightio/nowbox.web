require 'bundler'
Bundler.require :test
require_relative '../../aji'

include Rack::Test::Methods
def app
  Aji::API
end


