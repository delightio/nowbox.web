# Shares Controller
# =================
# Share object json:
#
# {`id`:1,
#  `user_id`: 12
#  `video_id`:1
#  `message`: "This is the funniest cat evar ZOMG!!!ONE~<3"
# }
module Aji
  class API
    version '1'
    # `http://API_HOST/1/shares`
    resource :shares do

      # ## GET shares/:share_id
      # __Returns__ the share with the specified id and HTTP Status Code 200 or
      # 404
      #
      # __Required params__ `share_id` unique id of the share
      #
      # __Optional params__ none
      get '/:share_id' do
        find_share_by_id_or_error params[:share_id]
      end

      # ## POST shares
      # *Requires authentication"
      #
      # __Creates__ a share object with the specified parameters.
      #
      # __Returns__ the created user and HTTP Status Code 201 if successful or
      # an error message and status code 400 or 401 if not.
      #
      # __Required params__
      #
      # - `user_id`: unique id of the current user
      #
      # - `video_id`: unique id of the shared video
      #
      # - `channel_id`: unique channel id of which shared video is in.
      #
      # - `network`: list of services to publish the share to.
      #     Can be `twitter` or `facebook`.
      #
      # __Optional params__
      #
      # - `message`: Text of the share message.
      #
      # - `video_start`: time in seconds, start of share segement (default to 0.0)
      #
      # - `video_elapsed` time in seconds, end of share segment (default to video duration)
      post do
        authenticate!

        video = Video.find_by_id params[:video_id]
        channel = Channel.find_by_id params[:channel_id]

        invalid_params_error! :video_id, params[:video_id],
          "No video with this id" if video.nil?
        invalid_params_error! :channel_id, params[:channel_id],
          "No channel with this id" if channel.nil?

        # keep track of the share event since client will only do
        # one POST /shares for triggering a share
        event = Event.create(:user => current_user, :action => :share,
          :video => video, :channel => channel,
          :video_start => params[:video_start].to_i,
          :video_elapsed => (params[:video_elapsed] || video.duration).to_i)

        begin
          share = Share.create(:user => current_user, :video => video,
            :channel => channel, :message => params[:message],
            :network => params[:network], :event => event)
        rescue => e
          # We couldn't publish the share to the given social network
          error! "User[#{current_user.id}] is unable to share Video[#{video.id}] to #{params[:network]}: #{e.message}", 400
        end

        validation_error!(share, params) unless share.valid?
        share

      end
    end
  end
end

