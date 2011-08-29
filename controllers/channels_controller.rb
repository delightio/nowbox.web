# Channels Controller
# =================
# Channel object json:
#
# {`id`:1,
#  `type`:"Trending",
#  `default_listing`:true,
#  `category_ids`: [1,2,3],
#  `title`:"Trending",
#  `thumbnail_uri`:"http://img.youtube.com/vi/cRBcP6MmE8g/0.jpg",
#  `resource_uri`:""http://api.nowmov.com/1/channels/1""}
module Aji
  class API
    version '1'
    # `http://API_HOST/1/channels`
    resource :channels do

      # ## GET channels/:channel_id
      # __Returns__ the channel with the specified id and HTTP Status Code 200
      # or 404
      #
      # __Required params__ `channel_id` unique id of the channel  
      # __Optional params__ none
      get '/:channel_id' do
        find_channel_by_id_or_error params[:channel_id]
      end

      # ## GET channels/
      # __Returns__ a list of channels matching the request parameters or all
      # channels if no parameters are specified.  
      # __Required params__ none  
      # __Optional params__  
      # - `user_id`:  user id. If supplied without `query`, server returns
      #   given user's subscribed channels.  
      # - `query`:  comma separated list of search term. Server returns all
      #   channels regardless of type.  
      get do
        channels = []
        if params[:query]
          channels += Channel.search params[:query]
        else
          user = User.find_by_id params[:user_id]
          channels = if user then
                        user.user_channels + user.subscribed_channels else
                        Channel.all end
        end
        channels
      end

      # ## GET channels/:channel_id/videos
      # __Returns__ all the videos of given channel and HTTP Status Code 200 or
      # 404  
      # __Required params__ `channel_id` unique id of the channel  
      # __Required params__ `user_id` unique id of the user  
      # __Optional params__ `limit` max. number of videos to return  
      # __Optional params__ `page` which page of videos to return
      get '/:channel_id/videos' do
        channel = find_channel_by_id_or_error params[:channel_id]
        user = find_user_by_id_or_error params[:user_id]
        channel.personalized_content_videos params.merge(:user=>user)
      end

    end
  end
end
