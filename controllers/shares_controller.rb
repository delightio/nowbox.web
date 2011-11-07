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
      # __Optional params__ none
      get '/:share_id' do
        find_share_by_id_or_error params[:share_id]
      end

      # ## POST shares
      # __Creates__ a share object with the specified parameters.
      # __Returns__ the created user and HTTP Status Code 201 if successful or
      # a JSON encoded error message if not.
      #
      # __Required params__
      # - `user_id`: unique id of the current user
      # - `video_id`: unique id of the shared video
      # - `channel_id`: unique channel id of which shared video is in.
      # - `network`: list of services to publish the share to.
      #     Can be `twitter` or `facebook`.
      #
      # __Optional params__
      # - `message`: Text of the share message.
      post do
        user = find_user_by_id_or_error params[:user_id]
        video = find_video_by_id_or_error params[:video_id]
        channel = find_channel_by_id_or_error params[:channel_id]
        share = Share.create( :user => user,
                              :video => video,
                              :channel => channel,
                              :message => params[:message],
                              :network => params[:network] )
        if share.errors.empty?
          share
        else
          creation_error Share, params
        end
      end
    end
  end
end

