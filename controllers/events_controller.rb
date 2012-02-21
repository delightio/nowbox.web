# Events Controller
# =================
module Aji
  class API
    version '1'
    resource :events do

      # ## POST events
      #
      # __Creates__ an event with given parameters.
      #
      # __Returns__ the created event and HTTP Status Code 201 if successful or
      # a JSON encoded error message if not.
      #
      # __Required params__
      #
      # `user_id` unique id of the action (user)
      #
      # `channel_id` unique id of the channel being acted on
      #
      # `action` action being triggered:
      #   channel: `subscribe`, `unsubscribe`
      #   video: `view`, `share`, `enqueue`, `dequeue`, `examine`, `favorite`, `unfavorite`
      #
      # __Optional params__
      # `reason` string containing the reason for examination
      #
      # When an video action is sent,
      #
      # __Required params__
      #
      # `video_id` unique id of the video being acted on.
      # if `video_id` is not present,
      #   `video_source` should be youtube
      #   `video_external_id` should be external ID of given video
      #
      # `video_elapsed` time in seconds from `video_start` when the event is triggered
      #
      # __Optional params__
      #
      # `video_start`: time in seconds when the event starts tracking (normally 0.0)
      #
      # `message`: the share message passed by the user when sharing a video.
      post do
        authenticate!

        p = params.delete_if {|k| k=="version" || k==:version}
        begin
          p = Event.parse_params p
          event = Event.create p
        rescue => e
          error!("Cannot create event from: #{p.inspect}. Error: #{e.inspect}", 400)
        end
      end
    end
  end
end
