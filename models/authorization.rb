module Aji
  class Authorization

    def initialize auth_hash, given_user
      @auth_hash = auth_hash
      @user = given_user
    end

    def account
      @account ||=
        if (account = provider_class.find_by_uid(@auth_hash['uid']))
          account.update_from_auth_info @auth_hash
        else
          provider_class.create(:identity => @user.identity,
                                :uid => @auth_hash['uid'],
                                :credentials => @auth_hash['credentials'],
                                :username => @auth_hash['nickname'],
                                :info => @auth_hash['extra']['user_hash'])
        end
    end

    def user
      if account.identity == @user.identity
        @user
      else
        account.identity.merge! @user.identity
        @user = account.identity.user
      end
    end

    def provider_class
      @provider_class ||= case @auth_hash['provider']
                          when 'twitter' then Account::Twitter
                          when 'facebook' then Account::Facebook
                          end
    end
  end
end
