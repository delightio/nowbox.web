# Users Controller
# =================
# User object json:
#
# {`id`:1,
#  `first_name`:"thomas",
#  `last_name`:null,
#  `queue_channel_id`: 7,
#  `favorite_channel_id`: 8,
#  `history_channel_id`: 9,
#  `subscribed_channel_ids`:[1,2,3,...]}
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
      # __Optional params__  
      # - `email` email address of the user  
      # - `first_name` first name of the user  
      # - `last_name` last name of the user
      post do
        User.create(:email => params[:email],
                    :first_name => params[:first_name],
                    :last_name => params[:last_name]) or
          creation_error!(User, params)
      end

      # ## PUT users/:user_id
      # __Updates__ given user's attributes  
      # __Returns__ HTTP Status Code 200 if successful or a JSON encoded error message  
      # __Required params__  
      # - `email` email address of the user
      put '/:user_id' do
        user = find_user_by_id_or_error params[:user_id]
        if params.has_key? :email
          user.update_attribute :email, params[:email]
        else
          missing_params_error! params, [:email]
        end
      end

    end
  end
end
