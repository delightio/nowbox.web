require 'rubygems'
require 'sinatra/base'
require 'pony'
require 'erubis'

# require_relative 'mailgun/mailgun'

module Aji
  class Mailer < Sinatra::Base
#     set :raise_errors, false 
#     set :show_exceptions, true if development? 

# 		Mailgun::init("key-038fp4b9sv6$r3sxa0")    

    # Use Erubis for template generation. Essentially a faster ERB.
     Tilt.register :erb, Tilt[:erubis]
			
     # Need to explicitly set the template directory:
     # http://stackoverflow.com/questions/3742486/sinatra-cannot-find-views-on-ruby-1-9-2-p0
     set :views, File.dirname(__FILE__) + "/views"
     set :public, File.dirname(__FILE__) + "/public"	  
 
		helpers do
			include Rack::Utils
		  alias_method :h, :escape_html
		end
		
		before do
			Pony.options = { 
        :from => 'nowmov <notifier@nowmov.mailgun.org>',
        :headers 		=> {'Content-Type' => 'text/html'},
        :via => :smtp, 
        :via_options => {
          :address      => 'smtp.mailgun.org',
          :port       	=> '587',
          :user_name    => 'postmaster@nowmov.mailgun.org',
          :password   	=> 'Baneling Bust',
          :authentication   => :plain,
          :domain     	=> 'nowmov.mailgun.org'
         }			
			}
		end
 		
		#########
		# ROUTES
		#########

		get '/welcome/:user_id/?' do
	    @user = User.find(params[:user_id])
			if(!params[:test]) 
		  	Pony.mail(
					:to=> @user.email,  
					:headers 		=> {'Content-Type' => 'text/html', 'X-Campaign-Id' => 'welcome', 'X-Mailgun-Tag' => 'welcome'},
          :subject=> "Welcome to nowmov",
          :body => erb(:'welcome.html'),
         )
			end
		  erb(:'welcome.html')		
		end

		get '/engager/:user_id/?' do
	    @user = User.find(params[:user_id])
			if(!params[:test]) 
			  Pony.mail(
					:to=> @user.email,  
					:headers 		=> {'Content-Type' => 'text/html', 'X-Campaign-Id' => 'engager', 'X-Mailgun-Tag' => 'engager'},
	        :subject=> "We Miss You!",
	        :body => erb(:'engager.html'),
	       )
			end
		  erb(:'engager.html')		
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
					:headers 		=> {'Content-Type' => 'text/html', 'X-Campaign-Id' => 'videos', 'X-Mailgun-Tag' => 'videos'},
	        :subject=> "Videos For You",
	        :body => erb(:'videos.html'),
	       )
		  end
		  erb(:'videos.html')		
		end		
  end
end
