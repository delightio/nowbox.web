# Videos Controller
# ================
# *Handles RESTful actions around [`Aji::Video`][VM] for the API*
# [VM]: ../models/video.html
module Aji
  class API
    # This is a version 1 controller so all actions are namespaced under
    # `http://API_HOST/1/`.
    version '1'

    # All actions are centered around the users resource and namespaced under
    # `http://API_HOST/1/users`
    resource :videos do
      # ## GET users [.json]  
      # __Returns__ a JSON serialized list of all videos with `id`, `title`,
      # `external_id`, and `description` and HTTP Code 200 OK if
      # successful, HTTP Code 400 otherwise.  
      # __Required params__ none.  
      # __Optional params__ `name`: name of a specific user to find.  
      get do
        Video.all
      end

    end
  end
end
