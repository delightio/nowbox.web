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
        find_video_by_id_or_error params[:video_id]
      end

      # ## PUT videos/:video_id
      # __Returns__ 200 if success; 400 if unsupported video action  
      # __Required params__ `video_id` unique id of the video  
      # __Required params__ `video_action` examine  
      put '/:video_id' do
        error!("Unknown video action: #{params[:video_action]}", 400) if !Supported.video_actions.include? params[:video_action].try(:to_sym)
        Resque.enqueue Aji::Queues::ExamineVideo, params[:video_id]
      end
    end
  end
end
