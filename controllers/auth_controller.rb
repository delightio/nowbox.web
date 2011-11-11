module Aji
  # NOTE: Since the AuthController is a Sinatra app and not part of our API
  # class it lacks the helper methods. We can fix that by passing a module for
  # helpers rather than the present method of injecting a block and instance
  # eval-ing.
  class AuthController < Sinatra::Base

    # If there's an OAuth Failure log it and return an error message.
    get '/failure' do
      content_type :json

      env_hash = request.env.dup
      Aji.log :WARN, "OAuth failure: #{env_hash.inspect}"
      [500, MultiJson.encode(:error => "Unable to authenticate at this time")]
    end

    # This is the entry point for OAuth'ing to other web services for Aji users.
    # At the moment, the only supported provider is Twitter but Facebook is high
    # priority and Youtube will probably follow shortly since there's a wealth
    # of preexisting data we can use there.
    #
    # To initiate an OAuth request an Aji client must do the following. For this
    # example we are assuming the target is iOS 4 and the provider is twitter.
    #
    # 1. Open a webkitview pane and point it to
    # `http://api.nowbox.com/auth/twitter?user_id=USER_ID` with query parameter
    # `user_id` specifying the internal user_id for the current Aji user.
    # 2. The webkitview is redirected to the Twitter application authorization
    # page with our application listed.
    # 3. The user must then log in and authorize our application (server-side)
    # to access their account and tweet on their behalf.
    # 4. Pending successful authorization the view will then be redirected to
    # `http://api.nowbox.com/auth/twitter/callback`. Ideally, *as soon as* this
    # redirect is initiated, the webkit view would close or grey out but content
    # from it must be captured by the iOS app.
    # 5. `http://api.nowbox.com/auth/twitter/callback` will return an updated
    # JSON blob to the webkitview containing the updated user model.
    #
    # *Youtube flow is the same as Twitter but replace `/auth/twitter?user_id`
    # with`/auth/you_tube?user_id`. Note the '_'*
    #
    # For Facebook Authentication the process is a little more complicated since
    # Facebook doesn't pass parameters outside of the callback url, which is
    # how we pass the user's id through Twitter.
    #
    # 1. Open a webkitview and point it to `http://api.nowbox.com/auth/facebook`
    # 2. The webkitview is redirected from our app to Facebook's tablet auth
    # page.
    # 3. The user logs in and authenticates with us. Giving us permission to
    # post to their wall, access their content offline, and see friends and
    # videos.
    # 4. This is where the primary difference between Twitter and Facebook is.
    # Upon successful authentication the redirect to
    # `api.nowbox.com/auth/facebook/callback` must be intercepted before it goes
    # back to our server and have the `user_id` parameter added to the end of
    # it. The webkitview can then be closed and the iOS backend can send the
    # final url back to the server. It will look something like:
    # `http://api.nowbox.com/auth/facebook/callback?code=LONGCODE&user_id=ID`
    # 5. That url will return an updated version of the user hash when the
    # account has been added.
    #
    # *Should the oauthentication fail for any reason the service will redirect
    # to `http://api.nowbox.com/auth/failure`.*
    #
    get '/:provider/callback' do
      content_type :json
      user = Aji::User.find_by_id params[:user_id]
      return [404,
        MultiJson.encode(:error => "User[#{params[:user_id]}] not found.")] if
        user.nil?

      begin
        auth_hash = request.env['omniauth.auth']

        # TODO: Replace case-when with `Account.const_get`
        provider_class = case auth_hash['provider']
                         when 'twitter' then Account::Twitter
                         when 'facebook' then Account::Facebook
                         when 'you_tube' then Account::Youtube
                         end

        account = provider_class.from_auth_hash auth_hash

        if account.class == Account::Youtube
          auth = Authorization.new account, user.identity
          auth.grant!
          user = auth.user
        else
          user.subscribe_social build_stream_channel
        end

        MultiJson.encode user.serializable_hash
      rescue => e
        Aji.log :WARN, "#{e.class}: #{e.message}"
        MultiJson.encode :error => 'Unable to authenticate',
          :message => e.message
      end
    end

    # ## POST /auth/you_tube/deauthorize
    # Creates a new user id and copies all exisiting channels
    # __Returns__ an updated version of the user resource.
    #
    # __Required params__
    # - `user_id`: The unique identifier of the user to be signed out of YouTube.

    post '/you_tube/deauthorize' do
      content_type :json

      user = User.find_by_id params[:user_id]
      if user.nil?
        return MultiJson.encode(
          :error => "User[#{params[:user_id]}] not found.")
      end
      if user.identity.nil?
        return MultiJson.encode(
          :error => "User[#{params[:user_id]}] has not been linked to any external accounts.")
      end

      accounts = user.identity.accounts.select { |a| a.class==Account::Youtube }
      if accounts.count != 1
        return MultiJson.encode(
          :error => "User[#{params[:user_id]}] has #{accounts.count} YouTube: #{accounts.inspect}")
      end
      account = accounts.first

      # Because we only allow 1 to 1 mapping of user and external accounts
      # like YouTube, i.e., a YouTube account always maps to the same user ID
      # We have no way of knowing when we can actually delete the
      # YouTube AND User objects. As a result, we always create a new one here.
      auth = Authorization.new account, account.identity
      new_user = auth.deauthorize!

      MultiJson.encode new_user.serializable_hash
    end


    # # ## POST /auth/:provider/deauthorize
    # # Deauthorizes an account effectively removing it from the system.
    # # __Returns__ an updated version of the user resource.
    # #
    # # __Required params__
    # # - `uid`: The unique identifier of the account to be deauthorized.
    # post '/:provider/deauthorize' do
    #   content_type :json
    #
    #   account = Account.find_by_uid_and_provider params[:uid], params[:provider]
    #
    #   if account.nil?
    #     return MultiJson.encode(:error => "No #{params[:provider]} account " +
    #                             "with uid:#{params[:uid]} known")
    #   end
    #
    #   auth = Authorization.new account, account.identity
    #
    #   auth.deauthorize!
    #
    #   MultiJson.encode auth.user.serializable_hash
    #
    # end

    # ## POST /auth/request_token
    # Securely get a user authentication token.
    # __Returns__ a JSON structure with a `token` and an `expires_at` timestamp.
    #
    # __Required params__
    # - `secret`: A client secret.
    # - `user_id`: identifier for the user to authenticate as.
    #
    # ***NOTE:*** This request must be made via HTTPS. Not doing so will result
    # in a 403 Forbidden.
    #
    # If the client secret is invalid then a 401 Unauthorized is returned.
    post '/request_token' do
      content_type :json

      force_ssl!
      validate_secret!

      user = User.find params[:user_id]
      tg = Token::Generator.new(user)

      MultiJson.encode(:token => tg.token, :expires_at => tg.expires_at.to_i)
    end

    helpers do
      def force_ssl!
        unless request.scheme == 'https'
          halt [403, '{"error":"Client must use HTTPS to generate tokens."}']
        end
      end

      def validate_secret!
        if params[:secret] != Aji.conf['CLIENT_SECRET']
          halt [401, '{"error":"Invalid client secret."}']
        end
      end
    end
  end
end

