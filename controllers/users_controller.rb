# Users Controller
# =================
# User object json:
#
# {`id`:1,
#  `name`:"thomas",
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
      # - `name` name of the user  
      # - `email` email address of the user
      post do
        User.create(:email => params[:email],
                    :name => params[:name]) or
          creation_error!(User, params)
      end

      # ## PUT users/:user_id
      # __Updates__ given user's attributes  
      # __Returns__ HTTP Status Code 200 if successful or a JSON encoded error message  
      # __Required params__ (need just one of the two)  
      # - `name` name of the user  
      # - `email` email address of the user
      put '/:user_id' do
        u = find_user_by_id_or_error params[:user_id]
        u.update_attribute(:name, params[:name]) if params.has_key? :name
        u.update_attribute(:email, params[:email]) if params.has_key? :email
        if !params.has_key?(:name) && !params.has_key?(:email)
          missing_params_error! params, [:email]
        end
      end

    end
  end
end
