# Channels Controller
# =================
# Channel object json:
#
# {`id`:1,
#  `type`:"Trending",
#  `default_listing`:true,
#  `category`:"undefined",
#  `title`:"Trending",
#  `thumbnail_uri`:"http://img.youtube.com/vi/cRBcP6MmE8g/0.jpg",
#  `resource_uri`:""http://aji.herokuapp.com/1/channels/1""}
module Aji
  class API
    version '1'
    # `http://API_HOST/1/channels`
    resource :channels do
      
      # ## GET channels/:channel_id
      # __Returns__ the channel with the specified id and HTTP Status Code 200 or 404
      #
      # __Required params__ `channel_id` unique id of the channel  
      # __Optional params__ none
      get '/:channel_id' do
        find_channel_by_id_or_error params[:channel_id]
      end
      
      # ## GET channels/
      # __Returns__ the default list of channels
      #
      # __Required params__ none  
      # __Optional params__ none
      get do
        Channel.default_listing
      end
      
      post do
        channel = Channel.create(params) or creation_error!(params)
      end
      
      # ## PUT channels/:channel_id
      # __Returns__ succeed or not on the given channel action and HTTP Status Code 200, 400 or 404
      #
      # __Required params__ `channel_id` unique id of the channel  
      # __Required params__ `channel_action` subscribe, unsubscribe, arrange  
      # __Optional params__ `channel_action_params[new_position]` new position for given channel
      put '/:channel_id' do
        channel = find_channel_by_id_or_error params[:channel_id]
        error!("Unknown channel action: #{params[:channel_action]}", 400) if !Supported.channel_actions.include? params[:channel_action].to_sym
        user = find_user_by_id_or_error params[:user_id]
        succeeded = user.send params[:channel_action], channel, params[:channel_action_params]
        error!("User[#{user.id}] cannot #{params[:channel_action]} Channel[#{channel.id}] with params: #{params[:channel_action_params].inspect}", 400) if !succeeded
      end
      
      # ## GET channels/:channel_id/videos
      # __Returns__ all the videos of given channel and HTTP Status Code 200 or 404
      #
      # __Required params__ `channel_id` unique id of the channel  
      # __Required params__ `user_id` unique id of the user  
      # __Optional params__ none
      get '/:channel_id/videos' do
        channel = find_channel_by_id_or_error params[:channel_id]
        user = find_user_by_id_or_error params[:user_id]
        channel.personalized_content_videos :user => user, :params => params
      end

    end
  end
end
