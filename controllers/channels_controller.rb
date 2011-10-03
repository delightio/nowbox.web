# Channels Controller
# =================
# Channel object json:
#
# {`id`:1,
#  `type`:"Trending",
#  `default_listing`:true,
#  `category_ids`: [1,2,3],
#  `title`:"Trending",
#  `video_count`: 25,
#  `thumbnail_uri`:"http://img.youtube.com/vi/cRBcP6MmE8g/0.jpg",
#  `resource_uri`:""http://api.nowbox.com/1/channels/1""}
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
      # __Optional params__ `inline_videos` integer, number of videos to include
      get '/:channel_id' do
        channel = find_channel_by_id_or_error params[:channel_id]
        channel.serializable_hash(
          :inline_videos => params[:inline_videos].to_i)
      end

      # ## GET channels/
      # __Returns__ a list of channels matching the request parameters or all
      # channels if no parameters are specified.  
      # __Required params__ none  
      # __Optional params__  
      # - `user_id`:  user id. If supplied without `query`, server returns
      #   given user's subscribed channels.  
      # - `query`:  comma separated list of search terms. Server returns all
      #   channels regardless of type.  
      get do
        channels = []
        if params[:query]
          channels = Searcher.new(params[:query]).results
        else
          user = User.find_by_id params[:user_id]
          channels = if user then
                        user.user_channels + user.subscribed_channels else
                        Channel::Account.all.sample(10) end
        end
        channels
      end

      # ## GET channels/:channel_id/videos
      # __Returns__ all the videos of given channel and HTTP Status Code 200 or
      # 404  
      # __Required params__  
      # - `channel_id` unique id of the channel  
      # - `user_id` unique id of the user  
      # __Optional params__  
      # - `limit` max. number of videos to return  
      # - `page` which page of videos to return, starts at 1
      get '/:channel_id/videos' do
        channel = find_channel_by_id_or_error params[:channel_id]
        user = find_user_by_id_or_error params[:user_id]
        channel.personalized_content_videos params.merge(:user=>user)
      end

      # ## POST channels/
      # __Returns__ new keyword channel created by given parameters  
      # __Required params__  
      # - `type`: channel type. Currently support: `keyword`  
      # - `query`:  comma separated list of search terms
      #
      post do
        creation_error!(Channel::Keyword, params) if params[:type] != 'keyword'
        not_found_error!(Channel::Keyword, params) if params[:query].nil?
        new_channel = Channel::Keyword.find_or_create_by_query params[:query]
        new_channel
      end

    end
  end
end
