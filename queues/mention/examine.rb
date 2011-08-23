module Aji
  module Queues
    module Mention
      class Examine
        extend WithDatabaseConnection
        @queue = :examine_mention

        def self.perform source, data, destination
          Resque.enqueue Queues::Mention::Process, source, data, destination
        end
      end
    end
  end
end