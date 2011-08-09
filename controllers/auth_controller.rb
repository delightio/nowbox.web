module Aji
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
    # `http://api.nowmov.com/auth/twitter`
    # 2. The webkitview is redirected to the Twitter application authorization
    # page with our application listed.
    # 3. The user must then log in and authorize our application (server-side)
    # to access their account and tweet on their behalf.
    # 4. Pending successful authorization the view will then be redirected to
    # `http://api.nowmov.com/auth/twitter/callback`. Ideally, *as soon as* this
    # redirect is initiated, the webkit view would close or grey out but content
    # from it must be captured by the iOS app.
    # 5. `http://api.nowmov.com/auth/twitter/callback` will return an updated
    # JSON blob to the webkitview containing the updated user model.
    #
    # *Should the oauthentication fail for any reason the service will redirect
    # to `http://api.nowmov.com/auth/failure`.*
    get '/:provider/callback' do
      user = find_user_by_id_or_error params[:user_id]
      auth_hash = request.env['omniauth.auth']
      auth_hash.inspect

      case params['provider']
      when 'twitter'
        t = Account::Twitter.find_or_create_by_uid(
          auth_hash['uid'], :identity => user.identity,
          :credentials => auth_hash['credentials'],
          :user_info => auth_hash['user_info'])
        t.serializable_hash.inspect
      else
        "Unsupported provider #{auth_hash['provider']}"
      end
    end
  end
end
