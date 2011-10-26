module Aji
  module Queues
    class Publish
      extend WithDatabaseConnection
      @queue = :publish_share

      def self.perform account_id, share_id
        Account.find(account_id).publish Share.find(share_id)
      end
    end
  end
end
