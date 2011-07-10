# This file is used by Rack-based servers to start the application.

require "#{File.expand_path(".")}/aji"

use Rack::Deflater
use Rack::Session::Cookie
use OmniAuth::Builder do
  provider :twitter, Aji.conf['CONSUMER_KEY'], Aji.conf['CONSUMER_SECRET']
  #provider :facebook, Aji.conf['APP_ID'], Aji.conf['APP_SECRET'],
  #  { :scope => 'publish_stream,offline_access' }
  #provider :identica, Aji.conf['identica_key'], Aji.conf['identica_secret']
end

map '/auth' do
  run Aji::AuthController
end

map '/resque' do
  use Rack::Auth::Basic do |username, password|
    [ username, password ] == [ "resque", "mellon" ]
  end
  run Resque::Server
end

map '/v' do
  run Aji::Viewer
end

map '/' do
  run Aji::API
end
