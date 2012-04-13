require 'sinatra/base'
require 'erubis'
require_relative 'route_helper'
require_relative 'view_helper'

module Aji

  class Viewer < Sinatra::Base
    set :raise_errors, false
    set :show_exceptions, true if development?

    # Use Erubis for template generation. Essentially a faster ERB.
    Tilt.register :erb, Tilt[:erubis]

    # Need to explicitly set the template directory:
    # http://stackoverflow.com/questions/3742486/sinatra-cannot-find-views-on-ruby-1-9-2-p0
    set :views, File.dirname(__FILE__) + "/views"
    set :public, File.dirname(__FILE__) + "/public"

    not_found do
      erb :'404', {:layout => :layout_error}
    end

    error do
      erb :'404', {:layout => :layout_error}
    end

    helpers do
      include Rack::Utils
      include Aji::RouteHelper
      include Aji::ViewHelper

      alias_method :h, :escape_html

      ### MOBILE ###

      # Regexes to match identifying portions of UA strings from iPhone and Android
      def mobile_user_agent_patterns
        [
          #/AppleWebKit.*Mobile/,
          /iPhone.*Mobile/,
          /Android.*AppleWebKit/
        ]
      end

      # Compares User Agent string against regexes of designated mobile devices
      def mobile_request?
        mobile_user_agent_patterns.any? {|r| request.env['HTTP_USER_AGENT'] =~ r}
      end

      # If there is a mobile version of the view, use that. Otherwise revert to normal view
      def mobile_file(name)
        mobile_file = "#{options.views}/#{name}#{@mobile}.erb"
        if File.exist? mobile_file
          view = "#{name}#{@mobile}"
        else
          view = "#{name}"
        end
      end

      # Set up rendering for partials
      def partial(name)
        erb mobile_file("_#{name}").to_sym, :layout => false
      end

      # Render appropriate file, with mobile layout if needed
      def deliver(name, layout)
        erb mobile_file(name).to_sym, :layout => :"#{layout}#{@mobile}"
      end
    end

    # Before responding to each request, verify if it came from a designated mobile device and set @mobile appropriately
    before do
      cache_control :public, :max_age => 1.day
      mobile_request? ? @mobile = ".mobile" : @mobile = ""
      @path = request.path_info
      @path.slice!(0)
    end

    #########
    # ROUTES
    #########

    get '/' do
      @ref = params[:ref] || ""
      @path = "home"
      erb :home, {:layout => :layout_homepage}
    end

    get '/about/?' do
      erb :about
    end

    get '/jobs/?' do
      erb :jobs
    end

    get '/tour/?' do
      erb :tour
    end

    get '/privacy/?' do
      erb :privacy
    end

    get '/press/?' do
      erb :press
    end

    get '/download/?' do
      redirect to("http://itunes.apple.com/us/app/nowbox/id464416202?mt=8&uo=4")
    end

    get '/launch/?' do
      @ref = params[:ref] || ""
      erb :launch, {:layout => :layout_splash}
    end

    get '/random' do
      random_share =  Share.offset(rand(Share.count)).first
      redirect to("/shares/#{random_share.id}")
    end

    get '/tos' do
      erb :tos
    end

    # get '/giveaway' do
    #   erb :giveaway, { :layout => :layout_giveaway }
    # end

    # get '/channel/:channel_id' do
    #   @channel = Channel.find(params[:channel_id]).serializable_hash(:inline_videos => 3 * 6)
    #
    #   deliver('channel', 'layout_channel')
    # end

    get '/videos/:video_id' do
      begin
        @share = nil
        @video = Video.find params[:video_id]
        @link = URI.escape @video.share_link
        @message = ""
        # + 2 so it's always even. We don't get a share event when sharing via email.
        @username = "#{2 + Share.where(:video_id => @video.id).count} people"
        @profile_pic = "/images/graphics/user_placeholder_image.png"

        erb :video, { :layout => :layout_video }

      rescue => e
        Aji.log :WARN, "#{e.class}: #{e.message}"
        erb :'404', {:layout => :layout_error}
      end
    end

    get '/shares/:share_id' do
       begin
        @share      = Share.find(params[:share_id])
        @video      = @share.video
        @link       = URI.escape @share.link
        @message    = @share.message
        @username   = @share.publisher.username
        @profile_pic= @share.publisher.thumbnail_uri

        erb :video, { :layout => :layout_video }

      rescue => e
        Aji.log :WARN, "#{e.class}: #{e.message}"
        erb :'404', {:layout => :layout_error}
      end
    end
  end
end
