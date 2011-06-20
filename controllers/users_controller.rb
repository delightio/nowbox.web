# Users Controller
# =================
# User object json:
#
# {`id`:1,
#  `first_name`:"thomas",
#  `last_name`:null,
#  `subscribed_chanel_ids`:["1","2","3","4","5","6"]}
module Aji
  class API
    version '1'
    # `http://API_HOST/1/users`
    resource :users do

      # ## GET users/:user_id
      # __Returns__ the user with the specified id and HTTP Status Code 200 or 404
      #
      # __Required params__ `user_id` unique id of the user  
      # __Optional params__ none
      get '/:user_id' do
        find_user_by_id_or_error params[:user_id]
      end

      # ## POST users
      # __Creates__ a user with the specified parameters.  
      # __Returns__ the created user and HTTP Status Code 201 if successful or
      # a JSON encoded error message if not.
      #
      # __Required params__ `email` email address of the user  
      # __Required params__ `first_name` first name of the user  
      # __Optional params__ `last_name` last name of the user
      post do
        User.create(:email => params[:email],
                    :first_name => params[:first_name],
                    :last_name => params[:last_name]) or
          creation_error!(User, params)
      end

    end
  end
end
