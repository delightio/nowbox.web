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
      # *Requires authentication* when getting a user channel.
      #
      # __Required params__ `channel_id` unique id of the channel
      #
      # __Optional params__ `inline_videos` integer, number of videos to include
      get '/:channel_id' do
        channel = find_channel_by_id_or_error params[:channel_id]

        if channel.class == Channel::User
          authenticate_as_token_holder!
          error! MultiJson.encode(:error => "Unathorized channel access"),
            401 unless current_user.user_channels.include? channel
        end

        channel.serializable_hash(
          :inline_videos => params[:inline_videos].to_i)
      end

      # ## GET channels/
      # __Returns__ a list of channels matching the request parameters or all
      # channels if no parameters are specified.
      #
      # __Required params__ none
      #
      # __Optional params__
      #
      # - `category_ids` and `type`:  `category_ids` is a comma separated list of
      #   category ids. Only supported `type` is 'featured'. Server then returns
      #   featured channels from these selected categories. `user_id` is required
      #   if `category_ids` is present.
      #
      # - `user_id`:  user id. If supplied without `query`, server returns
      #   given user's subscribed channels. Providing this parameter *requires
      #   authentication*.
      #
      # - `query`:  comma separated list of search terms. Server returns all
      #   channels regardless of type.
      get do
        if params[:query]
          Searcher.new(params[:query]).results
        elsif params[:category_ids]
          # TODO: we will user user.region later to determine the featured channels
          # to subscribe the user to given the selected categories
          missing_params_error! params, [:user_id] if current_user.nil?
          authenticate!

          missing_params_error! params, [:type] unless params[:type]=='featured'
          category_ids = params[:category_ids].split(',')
          categories = category_ids.map { |cat_id| Category.find_by_id cat_id }
          channels = categories.compact.map {|cat| cat.featured_channels.first(2) }
          channels.flatten.compact
        elsif (current_user)
          authenticate!

          current_user.display_channels
        else
          Channel::Account.all.sample(10)
        end
      end

      # ## GET channels/:channel_id/videos
      # __Returns__ all the videos of given channel and HTTP Status Code 200 or
      # 404
      #
      # *Requires authentication*
      #
      # __Required params__
      #
      # - `channel_id` unique id of the channel
      #
      # - `user_id` unique id of the user
      #
      # __Optional params__
      #
      # - `limit` max. number of videos to return
      #
      # - `page` which page of videos to return, starts at 1
      get '/:channel_id/videos' do
        authenticate!
        channel = find_channel_by_id_or_error params[:channel_id]
        channel.personalized_content_videos params.merge(
          :user => current_user)
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

