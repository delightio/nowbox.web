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
      # __Returns__ the user with the specified id and HTTP Status Code 200 or
      # 404
      #
      # __Required params__ `user_id` unique id of the user
      # __Optional params__ none
      # NEEDSAUTH
      get '/:user_id' do
        find_user_by_id_or_error params[:user_id]
      end

      # ## POST users
      # __Creates__ a user with the specified parameters.
      # __Returns__ the created user and HTTP Status Code 201 if successful or
      # a JSON encoded error message if not.
      #
      # __Required params__
      # - `language` language id tag given by iOS, string
      # - `locale` locale given by iOS, string
      #
      # __Optional params__
      # - `name` name of the user
      # - `email` email address of the user
      # - `time_zone` time zone info given by iOS, string
      post do
        region = Region.find_or_create_by_language_and_locale(
          params[:language], params[:locale]) ||
          Region.undefined
        User.create(:email => params[:email],
                    :name => params[:name],
                    :region => region) or
          creation_error!(User, params)
      end

      # ## PUT users/:user_id
      # __Updates__ given user's attributes
      # __Returns__ HTTP Status Code 200 if successful or a JSON encoded error
      # message
      # __Required params__ (need just one of the two params)
      # - `name` name of the user
      # - `email` email address of the user
      # NEEDSAUTH
      put '/:user_id' do
        u = find_user_by_id_or_error params[:user_id]
        updatable_params = [ :name, :email ]
        params_to_update = params.select do |key|
          updatable_params.include? key.to_sym
        end

        if params_to_update.empty?
          must_supply_params_error! updatable_params
        end
        u.update_attributes(params_to_update)
      end

      # ## GET users/:user_id/settings
      # __Returns__ JSON object representing the user's settings.
      # NEESAUTH
      get '/:user_id/settings' do
        find_user_by_id_or_error(params[:user_id]).settings
      end

      # ## PUT users/:user_id/settings
      # Acts as PATCH for now. When Grape gains PATCH support PUT will require
      # a complete representation of the settings hash.
      # __Updates__ User's updated settings JSON.  
      # __Returns__ JSON object representing the user's settings.  
      # __Required params__ `settings`: The form encoded represenation of the
      # user's settings.
      # NEESAUTH
      put '/:user_id/settings' do
        user = find_user_by_id_or_error params[:user_id]
        missing_params_error! params, [:settings] unless params[:settings]

        invalid_params_error! :settings, params[:settings],
          "Settings must be dictionary/hash" unless
          params[:settings].kind_of? Hash


        user.settings.tap do|settings|
          params[:settings].each do |k,v|
            settings[k.to_sym] = parse_param v
          end
        end

        user.save or error!
        user.settings
      end
    end
  end
end
