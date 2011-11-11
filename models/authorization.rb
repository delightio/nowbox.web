module Aji
  class Authorization
    attr_reader :user

    def initialize account, given_identity
      @account = account
      @identity = given_identity
    end

    def grant!
      case
      when @account.identity.nil?
        @account.identity = @identity
      when @account.identity != @identity
        @account.identity.merge! @identity
        @identity = @account.identity
      end

      @account.save
      @identity.save
      @user = @identity.user
      @account.authorize! @user
    end

    def deauthorize!
      new_user = User.create_from @account.user
      @account.deauthorize!

      new_user
    end
  end
end

