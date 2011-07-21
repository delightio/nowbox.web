module Aji
  class AuthController < Sinatra::Base

    get '/failure' do
      env_hash = request.env.dup
      env_hash.inspect
    end

    get '/:provider/callback' do
      auth_hash = request.env['omniauth.auth']
      auth_hash.inspect

      case params['provider']
      when 'twitter'
        t = ExternalAccounts::Twitter.find_or_create_by_uid(
          auth_hash['uid'],
          :credentials => auth_hash['credentials'],
          :user_info => auth_hash['user_info'])
        t.serializable_hash.inspect
      else
        "Unsupported provider #{auth_hash['provider']}"
      end
    end
  end
end
