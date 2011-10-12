module Aji
  class Authorization
    attr_reader :user

    def initialize account, given_identity
      @account = account
      @identity = given_identity
    end

    def grant!
      if @account.identity != @identity
        @account.identity.merge! @identity
        @identity = @account.identity
      end

      @user = @identity.user
    end

    def deauthorize!
      @user = @account.user

      @account.deauthorize!
    end
  end
end
