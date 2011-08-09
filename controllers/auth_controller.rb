module Aji
  class AuthController < Sinatra::Base

    get '/failure' do
      env_hash = request.env.dup
      env_hash.inspect
    end

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
