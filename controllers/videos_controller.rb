# Videos Controller
# =================
# Video object json:
#
#{`id`:1,
# `title`:"Did you hear a click?",
# `description`:"Rita and Frank try to take a still photo to email...",
# `thumbnail_uri`:"http://img.youtube.com/vi/cRBcP6MmE8g/0.jpg",
# `source`:"youtube",
# `external_id`:"cRBcP6MmE8g",
# `duration`:123,
# `view_count`:1328051,
# `published_at`:"2011-06-12T13:20:27-07:00",
# `author`:
# {`username`:"espo633",
# `profile_uri`:"http://www.youtube.com/user/espo633",
# `external_account_id`:1}
# }
module Aji
  class API
    version '1'
    # `http://API_HOST/1/videos`
    resource :videos do

      # ## GET videos/:video_id
      # __Returns__ the video with the specified id and HTTP Status Code 200 or 404
      #
      # __Required params__ `video_id` unique id of the video  
      # __Optional params__ none
      get '/:video_id' do
        publicly_cacheable! 1.hour
        find_video_by_id_or_error params[:video_id]
      end
    end
  end
end
