module Queues
  class PublishShare
    @queue = :publish_share

    def self.perform account_id, share_id
      acc = Account.find(account_id)
      share = Share.find(share_id)

      acc.publish share.message
    end
  end
end
