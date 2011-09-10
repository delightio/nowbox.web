module Aji
  module Queues
    class RemoveSpammer
      extend WithDatabaseConnection

      @queue = :remove_spammer
      @spammer_set_key = "spammers"

      def self.perform spammer_id
        spammer = Account.find spammer_id
        Aji.redis.zincrby "spammers", 1, spammer.id
        Aji.log "* Spammer: #{spammer.id}: m: #{spammer.mentions.map(&:id)}"
        spammer.mark_spammer
      end
    end
  end
end
