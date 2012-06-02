module Aji
  module Queues
    module Debug
      class FixRedistogoCategories
        extend WithDatabaseConnection
        @queue = :debug

        def self.perform
          start = Time.now
          Aji.log "FixRedistogoCategories started"
          Channel::Account.find_each do |ch|
            next if ch.relevance < 200

            ch.update_relevance_in_categories
            Aji.log "* Channel[#{ch.id}] updated categories"
          end
          Aji.log "FixRedistogoCategories ended in #{Time.now-start}"
        end

      end
    end
  end
end
