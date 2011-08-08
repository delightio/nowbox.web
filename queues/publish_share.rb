module Queues
  class PublishShare
    @queue = :publish_share

    def self.perform external_account_id, share_id
      acc = Account.find(external_account_id)
      share = Share.find(share_id)

      acc.publish share.message
    end
  end
end
