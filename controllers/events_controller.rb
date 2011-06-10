module Aji
  class API
    version '1'
    resource :events do

      post '/' do
        event = Event.create(params) or
          cannot_create_event_error(params)
        event
      end

      helpers do
        def cannot_create_event_error params
          error! "Cannot create event from: #{params.inspect}", 400
        end
        def user_not_found_error id
          error! "User[#{id}] cannot be found", 404
        end
      end
    end
  end
end
