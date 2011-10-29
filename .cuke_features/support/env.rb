ENV['RACK_ENV'] = 'test'
require 'bundler'
Bundler.require :test
require_relative '../../aji'

#VCR.config do |c|
#  c.cassette_library_dir = "#{Aji.root}/cassettes"
#  c.ignore_hosts 'gdata.youtube.com'
#  c.stub_with :fakeweb
#  c.default_cassette_options = { :record => :new_episodes }
#end

include Rack::Test::Methods
def app
  Aji::API
end


