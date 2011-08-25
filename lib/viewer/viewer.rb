require 'sinatra/base'
require 'erubis'

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
      erb :home
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

    get '/download/?' do
    	@ref = params[:ref] || ""
      erb :launch, {:layout => :layout_splash}
    end

    get '/launch/?' do
    	@ref = params[:ref] || ""
      erb :launch, {:layout => :layout_splash}
    end
    
    get '/random/?' do 
    	random =  Share.offset(rand(Share.count)).first.id
    	redirect to('/'+random.to_s)
    end
    
  	get '/:share_id/?' do
       begin
      	@share = Share.find(params[:share_id])
      	@user = @share.user
	      @video = @share.video
	
	      
	      @user_shares = Share.where("user_id = ? AND id <> ?", @user.id, @share.id).limit(18)
	      
		    deliver('video', 'layout_video')
      rescue
 				erb :'404', {:layout => :layout_error} 
      end
  	end	  	
  end
end
