require 'sinatra/base'

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

		before do
#				Use the following to debug params
# 		  puts '[Params]'
# 		  p params
		end


 		not_found do
 			erb :'404', {:layout => :layout_error} 
 		end

 		error do
 		  erb :'404', {:layout => :layout_error}
 		end 
		
    get '/' do
    	@ref = params[:ref] || ""
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
    	@ref = params[:ref] || ""
      erb :launch, {:layout => :layout_splash}
    end

    get '/launch' do
    	@ref = params[:ref] || ""
      erb :launch, {:layout => :layout_splash}
    end
    
    get '/random' do 
    	random =  Share.offset(rand(Share.count)).first.id
    	redirect to('/'+random.to_s)
    end
    
  	get '/:share_id' do
      begin
      	@share = Share.find(params[:share_id])
      	@user = @share.user
	      @video = @share.video
	
	      
	      @user_shares = Share.where("user_id = ? AND id <> ?", @user.id, @share.id).limit(18)
	      
	      if(params[:mobile] == 'true')
	      	erb :mobile_video, {:layout => :layout_mobile}
	      else
		      erb :video, {:layout => :layout_video}
		    end   
      rescue
 				erb :'404', {:layout => :layout_error} 
      end
  	end	  	
  end
end
