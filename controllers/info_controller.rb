# Info Controller
# ===============
# Info resource JSON:  
# { `current_version`: "VERSION_STRING",  
#   `minimum_version`: "VERSION_STRING",  
#   `link`: {  
#     `rel`: "latest",  
#     `url`: "APP_URL"  
#   }  
# }
module Aji
  class API
    version '1'

    # http://API_HOST/1/info
    resource :info do
      # ## GET info
      # __Returns__ information about the API and client applications.  
      # __Optional params__ `device`: must be one of `android_tablet`,
      # `android_handset`, `ipad`, `iphone`
      get do
        begin
          Info.for_device params[:device]
        rescue => e
          error!({ :error => e.message }, 400)
        end
      end
    end
  end
end
