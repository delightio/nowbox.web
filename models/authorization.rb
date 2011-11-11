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

    # Because we only allow 1 to 1 mapping of user and external accounts
    # like YouTube, i.e., a YouTube account always maps to the same user ID.
    # It is possible that same user ID will be on multiple devices.
    # Thus, we have no way of knowing when we can actually delete the
    # YouTube AND User objects. As a result, we returns a new copy of the
    # current user.
    def deauthorize!
      User.create_from @account.user
    end
  end
end

