module Aji
  class Channels::TwitterAccount < Channel
    belongs_to :account, :class_name => 'Aji::ExternalAccounts::Twitter'
    before_create :set_default_title


    # Class methods below
    def self.find_or_create_by_account account, params={}
      account.channel ||= Channels::TwitterAccount.create(params.merge(
        :account => account))
    end

    # Private instance methods below.
    private
    def set_default_title
      self.title ||= "@#{account.handle}'s Tweeted Videos"
    end
  end
end
