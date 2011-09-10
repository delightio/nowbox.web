module Aji
  module Queues
    class RemoveSpammer
      extend WithDatabaseConnection

      @queue = :remove_spammer
      @spammer_set_key = "spammers"

      def self.perform spammer_id
        spammer = Account.find spammer_id
        spammer.blacklist
        Aji.log "* spammer * Account[#{spammer.id}] was found to be spammy.\n" +
          "You can find them and all other spammers in the redis set " +
          "'#{@spammer_set_key}'"
        Aji.redis.sadd @spammer_set_key, spammer.id
      end
    end
  end
end
