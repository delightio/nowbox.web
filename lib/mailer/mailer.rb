require 'rubygems'
require 'sinatra/base'
require 'pony'
require 'erubis'

# require_relative 'mailgun/mailgun'

module Aji
  class Mailer < Sinatra::Base
#     set :raise_errors, false 
#     set :show_exceptions, true if development?

#     Mailgun::init("key-038fp4b9sv6$r3sxa0")

    # Use Erubis for template generation. Essentially a faster ERB.
     Tilt.register :erb, Tilt[:erubis]

     # Need to explicitly set the template directory:
     # http://stackoverflow.com/questions/3742486/sinatra-cannot-find-views-on-ruby-1-9-2-p0
     set :views, File.dirname(__FILE__) + "/views"
     set :public, File.dirname(__FILE__) + "/public"

    helpers do
      include Rack::Utils
      alias_method :h, :escape_html

      # Source: http://snippets.dzone.com/posts/show/4578
      def shorten_by_words string, word_limit = 5
        words = string.split(/\s/)
        if words.size >= word_limit
          last_word = words.last
          words[0,(word_limit-1)].join(" ") + ' ... ' + last_word
        else
          string
        end
      end

      def shorten string, limit = 140
        words = string.split(/\s/)
        if string.size >= limit
          string[0,(limit-1)] + ' ... '
        else
          string
        end
      end
    end

    before do
      Pony.options = {
        :from => 'nowbox <notifier@nowbox.mailgun.org>',
        :headers    => {'Content-Type' => 'text/html'},
        :via => :smtp,
        :via_options => {
          :address      => 'smtp.mailgun.org',
          :port         => '587',
          :user_name    => 'postmaster@nowbox.mailgun.org',
          :password     => '56og9umqu265',
          :authentication   => :plain,
          :domain       => 'nowbox.mailgun.org'
         }
      }
    end

    #########
    # ROUTES
    #########

    get '/welcome/:user_id/?' do
      @user = User.find(params[:user_id])

      # TODO: Really awesome query that gives the most interesting not-seen-before videos
      @shares = Share.find(:all, :order => "id desc", :limit => 5)

      # Find the last 5 recently populated channels
        # index_by: to remove duplicates
        # sort_by: to get he most recent channels
#       @channels = @user.subscribed_channels.index_by{|c| c.id}.values.sort_by{|c| - c.populated_at.to_i rescue nil}[0...10]


      if(!params[:test])
        Pony.mail(
          :to=> @user.email,
          :headers    => {'Content-Type' => 'text/html', 'X-Campaign-Id' => 'welcome', 'X-Mailgun-Tag' => 'welcome'},
          :subject=> "Welcome to nowbox",
          :body => erb(:'welcome.html'),
         )
      end
      erb(:'welcome.html')
    end

    get '/channels/:user_id/?' do
      @user = User.find(params[:user_id])

      # TODO: We can recommend any kind of channel, not just subscribed channels
      # Find the last 5 recently populated channels
        # index_by: to remove duplicates
        # sort_by: to get he most recent channels
      channels_for_user = @user.subscribed_channels.index_by{|c| c.id}.values.sort_by{|c| - c.populated_at.to_i rescue nil}[0...3]
      channels_for_user << Channel.find(@user.queue_channel_id)

      @channels = Array.new
      channels_for_user.each do |channel|
        videos = channel.personalized_content_videos(:user => @user).last(3)
        if videos.length > 0
          channel['videos'] = videos
          channel['subscribed'] = true # TODO: Is the user subscribed to this channel or not
          channel['reason'] = '' # TODO: Why is this channel recommended?
          @channels << channel
        end
      end

      if(!params[:test])
        Pony.mail(
          :to=> @user.email,
          :headers    => {'Content-Type' => 'text/html', 'X-Campaign-Id' => 'channels', 'X-Mailgun-Tag' => 'channels'},
          :subject=> "Nowbox Weekly Channel Guide",
          :body => erb(:'channels.html'),
         )
      end
      erb(:'channels.html')
    end

    get '/videos/:user_id/?' do
      @user = User.find(params[:user_id])

      # TODO: Really awesome query that gives the most interesting not-seen-before videos
      @shares = Share.find(:all, :order => "id desc", :limit => 5)

      # Find the last 5 recently populated channels
        # index_by: to remove duplicates
        # sort_by: to get he most recent channels
      @channels = @user.subscribed_channels.index_by{|c| c.id}.values.sort_by{|c| - c.populated_at.to_i rescue nil}[0...10]

      if(!params[:test])
        Pony.mail(
          :to=> @user.email,
          :headers    => {'Content-Type' => 'text/html', 'X-Campaign-Id' => 'videos', 'X-Mailgun-Tag' => 'videos'},
          :subject=> "Nowbox Weekly Videos Guide",
          :body => erb(:'videos.html'),
         )
      end
      erb(:'videos.html')
    end
  end
end
