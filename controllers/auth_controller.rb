module Aji
  # NOTE: Since the AuthController is a Sinatra app and not part of our API
  # class it lacks the helper methods. We can fix that by passing a module for
  # helpers rather than the present method of injecting a block and instance
  # eval-ing.
  class AuthController < Sinatra::Base

    # If there's an OAuth Failure log it and return an error message.
    get '/failure' do
      env_hash = request.env.dup
      Aji.log :WARN, "OAuth failure: #{env_hash.inspect}"
      error "OAuth authentication failed", 500
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
    # *Should the oauthentication fail for any reason the service will redirect
    # to `http://api.nowbox.com/auth/failure`.*
    get '/:provider/callback' do
      user = Aji::User.find_by_id params[:user_id]
      return { :error => "User[#{params[:user_id]}] does not exist." } if
        user.nil?
      auth_hash = request.env['omniauth.auth']

      case params['provider']
      when 'twitter'
        t = Account::Twitter.find_by_uid(
          auth_hash['extra']['user_hash']['uid'].to_s)
        unless t.nil?
          t.update_attributes(
            :info => auth_hash['extra']['user_hash'],
            :identity => user.identity,
            :credentials => auth_hash['credentials'],
            :info => auth_hash['extra']['user_hash'])
        else
          t ||= Account::Twitter.create(
            :username => auth_hash['extra']['user_hash']['screen_name'],
            :uid => auth_hash['uid'].to_s,
            :identity => user.identity,
            :credentials => auth_hash['credentials'],
            :info => auth_hash['extra']['user_hash'])
        end

      else
        "Unsupported provider #{auth_hash['provider']}"
      end
      Resque.enqueue Aji::Queues::UpdateGraphChannel, user.identity.id
      MultiJson.encode user.serializable_hash
    end
  end
end
