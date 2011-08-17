module Aji
  module Queues
    module WithDatabaseConnection
      def self.before_perform
        ActiveRecord::Base.establish_connection Aji.conf['DATABASE']
      end

      def self.after_perform
        ActiveRecord::Base.connection.disconnect!
      end
    end
  end
end
