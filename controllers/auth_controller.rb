class Aji::AuthHandler < Sinatra::Base
  get '/:provider/callback' do
    auth_hash = request.env['omniauth.auth']

    case params[:provider]
    when 'twitter'
      t = ExternalAccounts::Twitter.find_or_create_by_provider_and_uid(
        auth_hash['provider'], auth_hash['uid'],
        :user_info => auth_hash['user_info'],
        :credentials => auth_hash['credentials'])
      t.serializable_hash
    else
      [ "Provider #{params[:provider]} not implemented.",
        { 'Content-Type' => 'application/json' }, 400 ]
    end
  end
end
