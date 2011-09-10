module Aji
  module Queues
    class RemoveSpammer
      extend WithDatabaseConnection

      @queue = :remove_spammer
      @spammer_set_key = "spammers"

      def self.perform spammer_id
        spammer = Account.find spammer_id
        spammer.mark_spammer
        Aji.redis.zincrby "spammers", 1, spammer.id
      end
    end
  end
end
