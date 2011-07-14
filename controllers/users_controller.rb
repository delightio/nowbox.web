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

      # ## GET users/:user_id
      # __Returns__ succeed or not on the given channel action and HTTP Status
      # Code 200, 400 or 404  
      # __Required params__ `channel_id` unique id of the channel  
      # __Required params__ `channel_action` subscribe, unsubscribe, arrange  
      # __Optional params__ `channel_action_params[new_position]` new position
      # for given channel
      put '/:user_id' do
        channel = find_channel_by_id_or_error params[:channel_id]
        error!("Unknown channel action: #{params[:channel_action]}", 400) if !Supported.channel_actions.include? params[:channel_action].try(:to_sym)
        user = find_user_by_id_or_error params[:user_id]
        succeeded = user.send params[:channel_action], channel, params[:channel_action_params]
        error!("User[#{user.id}] cannot #{params[:channel_action]} Channel[#{channel.id}] with params: #{params[:channel_action_params].inspect}", 400) if !succeeded
      end

    end
  end
end
