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
use HireFireApp::Middleware

map "http://beta.#{Aji.conf['TLD']}/" do
  run Aji::Viewer
end

map "http://mailer.#{Aji.conf['TLD']}/" do
  run Aji::Mailer
end

map '/auth' do
  run Aji::AuthController
end

map "http://resque.#{Aji.conf['TLD']}/" do
  use Rack::Auth::Basic do |username, password|
    [ username, password ] == [ "resque", "mellon" ]
  end
  run Resque::Server
end

map "http://api.#{Aji.conf['TLD']}/" do
  run Aji::API
end

map "http://apidoc.#{Aji.conf['TLD']}/" do
  use Rack::Auth::Basic do |username, password|
    [ username, password ] == [ "apidoc", "water" ]
  end
  use Rack::Static, :urls => { '/' => 'aji.html' }, :root => 'docs'
  run Rack::Directory.new('docs')
end
