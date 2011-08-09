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
      # __Optional DEBUG params__  
      # - `debug_min_count`:  integer. If present and used with `query`, server
      #   will ensure the number of search result is at least `debug_min_count`.
      get do
        channels = []
        if params[:query]
          channels += Channel.search params[:query]
          if params[:debug_min_count] # TODO debug only
            min_count = params[:debug_min_count].to_i
            if min_count.to_s != params[:debug_min_count]
              error! "debug_min_count needs to be an integer", 500
            end
            if Channel.count > min_count
              while channels.count < min_count
                channels << Channel.first(:offset => rand(Channel.count))
                channels.uniq!
              end
            end
          end
        else
          user = User.find_by_id params[:user_id]
          if user
            user.subscribed_channels
          else
            Channel.all
          end
        end
      end

      # ## GET channels/:channel_id/videos
      # __Returns__ all the videos of given channel and HTTP Status Code 200 or
      # 404  
      # __Required params__ `channel_id` unique id of the channel  
      # __Required params__ `user_id` unique id of the user  
      # __Optional params__ `limit` max. number of videos to return
      get '/:channel_id/videos' do
        channel = find_channel_by_id_or_error params[:channel_id]
        user = find_user_by_id_or_error params[:user_id]
        channel.personalized_content_videos params.merge(:user=>user)
      end

    end
  end
end
