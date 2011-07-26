module Aji
  class Channels::TwitterAccount < Channel
    belongs_to :account, :class_name => 'Aji::ExternalAccounts::Twitter'
    before_create :set_default_title

    private
    def set_default_title
      self.title ||= "@#{account.handle}'s Tweeted Videos"
    end
  end
end
