# Events Controller
# =================
module Aji
  class API
    version '1'
    resource :events do

      # ## POST events
      # __Creates__ an event with given parameters.  
      # __Returns__ the created event and HTTP Status Code 201 if successful or
      # a JSON encoded error message if not.
      #
      # __Required params__ `user_id` unique id of the action (user)  
      # __Required params__ `channel_id` unique id of the channel being acted on  
      # __Required params__ `action` action being triggered:  
      # channel: `subscribe`, `unsubscribe`  
      # video: `view`, `share`, `upvote`, `downvote`, `enqueue`, `dequeue`, `examine`  
      #   
      # When an video action is sent,  
      # __Required params__ `video_id` unique id of the video being acted on  
      # __Required params__ `video_elapsed` time in seconds from `video_start` when the event is triggered  
      # __Optional params__ `video_start` time in seconds when the event starts tracking (normally 0.0)
      post do
        p = params.delete_if {|k| k=="version" || k==:version}
        begin
          event = Event.create(p)
        rescue => e
          error!("Cannot create event from: #{p.inspect}. Error: #{e.inspect}", 400)
        end
      end
    end
  end
end
