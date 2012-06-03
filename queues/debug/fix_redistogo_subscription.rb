module Aji
  module Queues
    module Debug
      class FixRedistogoSubscription
        extend WithDatabaseConnection
        @queue = :debug

        def self.perform user_id
          start = Time.now
          puts "FixRedistogoSubscription started with User[#{user_id}]"
          user = User.find user_id
          return if user.nil?

          user.events.order('created_at asc').each do |e|
            ch = e.channel
            next if ch.nil?

            case e.action
            when :unsubscribe
              user.unsubscribe ch
            else
              user.subscribe ch
            end

            puts "FixRedistogoSubscription: User[#{user.id}] #{e.action} #{e.channel.title}"
          end
          puts "FixRedistogoSubscription: User[#{user.id}] done in #{Time.now-start}"
        end

      end
    end
  end
end
