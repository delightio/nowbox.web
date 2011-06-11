# This file is used by Rack-based servers to start the application.

require "#{File.expand_path(".")}/aji"

use Rack::Session::Cookie
use OmniAuth::Builder do
  provider :twitter, Aji.conf['consumer_key'], Aji.conf['consumer_secret']
  #provider :facebook, Aji.conf['app_id'], Aji.conf['app_secret',
  #  { :scope => 'publish_stream,offline_access' }
  #provider :identica, Aji.conf['identica_key'], Aji.conf['identica_secret']
end
run Aji::API
