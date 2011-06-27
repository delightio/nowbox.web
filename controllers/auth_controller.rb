module Aji
  class API
    namespace :auth do
      get '/:provider/callback' do
        auth_hash = request.env['omniauth.auth']

        case params[:provider]
        when :twitter
          t = ExternalAccounts::Twitter.find_or_create_by_provider_and_uid(
            auth_hash['provider'], auth_hash['uid'],
            :user_info => auth_hash['user_info'],
            :credentials => auth_hash['credentials'])
          user = User.find_by_external_account(t) || User.create do |u|
            u.external_accounts << t
          end
        else
          error! "Provider #{params[:provider]} not implemented.", 400
        end
      end
    end
  end
end
