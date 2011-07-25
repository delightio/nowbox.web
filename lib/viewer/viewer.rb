require 'sinatra/base'

module Aji
  class Viewer < Sinatra::Base
    # Use Erubis for template generation. Essentially a faster ERB.
    Tilt.register :erb, Tilt[:erubis]
    # Need to explicitly set the template directory:
    # http://stackoverflow.com/questions/3742486/sinatra-cannot-find-views-on-ruby-1-9-2-p0
    set :views, File.dirname(__FILE__) + "/views"
    set :public, File.dirname(__FILE__) + "/public"

    get '/' do
    	@ref = params[:ref] || ""
      erb :launch, {:layout => :layout_splash}
    end

    get '/home' do
      erb :home
    end
    
    get '/about' do
      erb :about
    end

    get '/jobs' do
      erb :jobs
    end

    get '/tour' do
      erb :tour
    end

    get '/download' do
      erb :download
    end

    get '/launch' do
      erb :launch, {:layout => :layout_splash}
    end
    
    get '/:share_id' do
      #@share = Share.find params[:share_id]
      erb :video
    end
  end
end
