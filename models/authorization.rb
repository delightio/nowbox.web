module Aji
  class Authorization
    def initialize auth_hash, given_identity
      @auth_hash = auth_hash
      @identity = given_identity
    end

    def account
      @account ||=
        if (account = provider_class.find_by_uid(@auth_hash['uid']))
          account.update_from_auth_info @auth_hash
          account
        else
          provider_class.create(:identity => @identity,
                                :uid => @auth_hash['uid'],
                                :credentials => @auth_hash['credentials'],
                                :username => @auth_hash['nickname'],
                                :info => @auth_hash['extra']['user_hash'])
        end
    end

    def user
      @user ||= if account.identity == @identity
                  @identity.user
                else
                  account.identity.merge! @identity
                  account.identity.user
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
