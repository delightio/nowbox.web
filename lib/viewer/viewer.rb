require 'sinatra/base'


module Aji
  class Viewer < Sinatra::Base
    # Use Erubis for template generation. Essentially a faster ERB.
    Tilt.register :erb, Tilt[:erubis]

    get '/:share_id' do
      @share = Share.find params[:share_id]
      erb :play_share
    end
  end
end
