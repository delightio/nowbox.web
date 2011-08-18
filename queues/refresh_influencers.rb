module Aji
  module Queues
    class UpdateGraphChannel
      extend WithDatabaseConnection

      @queue = :graph_channel

      def self.perform identity_id
        identity = Identity.find_by_id identity_id
        identity.accounts.each do |a|
          a.refresh_influencers if a.respond_to? :refresh_influencers
        end

        identity.update_graph_channel
      end
    end
  end
end
