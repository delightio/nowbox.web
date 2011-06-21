# This file is used by Rack-based servers to start the application.

require "#{File.expand_path(".")}/aji"

use Rack::Session::Cookie
use OmniAuth::Builder do
  provider :twitter, Aji.conf['CONSUMER_KEY'], Aji.conf['CONSUMER_SECRET']
  #provider :facebook, Aji.conf['app_id'], Aji.conf['app_secret',
  #  { :scope => 'publish_stream,offline_access' }
  #provider :identica, Aji.conf['identica_key'], Aji.conf['identica_secret']
end


run Aji::API
#run Rack::URLMap.new '/1' => Aji::API, '/' => Aji::Viewer
