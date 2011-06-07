module Aji
  class API
    version '1'
    
    resource :channels do
      
      get '/:channel_id' do
        channel = Channel.find params[:channel_id] or
          no_channel_error params[:channel_id]
      end
      
      get '/live/videos' do
        channel = Channel.live
        channel.videos
      end
      
      get '/:channel_id/videos/' do
        channel = Channel.find params[:channel_id] or
          no_channel_error params[:channel_id]
        channel.videos
      end
      
      helpers do
        def no_channel_error id
          error! "Channel[#{id}] does not exist", 404
        end
      end
      
    end
  end
end
