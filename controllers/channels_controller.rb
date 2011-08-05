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
      # - `user_id`: user id
      # - `query`: comma separated list of search terms.
      #   Server will return all channels regardless of type that fuzzy match
      #   the given query
      # - `debug`: a debug code to list out all channels if user_id is missing.
      
      get do
        user = User.find_by_id params[:user_id]
        channels = []
        if !params[:query]
          channels =
            if user
              user.subscribed_channels
            else
              if params[:debug] == 'BOzET83g' # LH 158
                Channel.all
              else
                error! "Missing parameters.", 404
              end
            end
        else
          query = params[:query]
          separator = ','
          channels += Channel.search query, separator
          keywords = query.split separator
          keyword_based = Channels::Keyword.find_or_create_by_keywords keywords
          unless channels.include? keyword_based
            keyword_based.populate
            channels << keyword_based
          end
        end
        channels
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
