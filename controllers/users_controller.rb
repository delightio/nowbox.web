# Users Controller
# ================
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
      # *Requires authentication*  
      # __Returns__ the user with the specified id and HTTP Status Code 200 or
      # 404
      #
      # __Required params__ `user_id` unique id of the user  
      # __Optional params__ none
      get '/:user_id' do
        not_found_error! User, params unless current_user
        authenticate!
        current_user
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
      # *Requires authentication*  
      # __Updates__ given user's attributes  
      # __Returns__ HTTP Status Code 200 if successful or a JSON encoded error
      # message  
      # __Required params__ (need just one of the two params)
      # - `name` name of the user
      # - `email` email address of the user
      put '/:user_id' do
        authenticate!

        updatable_params = [ :name, :email ]
        params_to_update = params.select do |key|
          updatable_params.include? key.to_sym
        end

        if params_to_update.empty?
          must_supply_params_error! updatable_params
        end

        if current_user.update_attributes(params_to_update)
          current_user
        else
          error! current_user.errors, 400
        end
      end

      # ## GET users/:user_id/settings
      # *Requires authentication*  
      # __Returns__ JSON object representing the user's settings.
      get '/:user_id/settings' do
        authenticate!

        current_user.settings
      end

      # ## PUT users/:user_id/settings
      # *Requires authentication*  
      # Acts as PATCH for now. When Grape gains PATCH support PUT will require
      # a complete representation of the settings hash.  
      # __Updates__ User's updated settings JSON.  
      # __Returns__ JSON object representing the user's settings.  
      # __Required params__ `settings`: The form encoded represenation of the
      # user's settings.
      # NEESAUTH
      put '/:user_id/settings' do
        authenticate!

        missing_params_error! params, [:settings] unless params[:settings]

        invalid_params_error! :settings, params[:settings],
          "Settings must be dictionary/hash" unless
          params[:settings].kind_of? Hash


        current_user.settings.tap do|settings|
          params[:settings].each do |k,v|
            settings[k.to_sym] = parse_param v
          end
        end

        current_user.save or error!
        current_user.settings
      end

      # ## POST users/:user_id/synchronize
      # *Requires authentication*
      #
      # __Returns__ 202 when a sync has been successfully enqueued. 401 if
      # unauthorized or 400 if the user has no youtube account.
      #
      # __Parameters__ none
      post '/:user_id/synchronize' do
        authenticate!

        if account = current_user.identity.youtube_account
          YoutubeSync.new(account).background_synchronize! :disable_resync
          status 202
          current_user
        else
          status 400
          {:error => "No youtube account associated with the current user"}
        end
      end

      # ## GET users/:user_id/auth_test
      # *Requires authentication*
      get '/:user_id/auth_test' do
        authenticate!
        "OK"
      end
    end
  end
end

