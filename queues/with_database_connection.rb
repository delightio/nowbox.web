module Aji
  module Queues
    module WithDatabaseConnection
      def self.around_perform
        ActiveRecord::Base.establish_connection Aji.conf['DATABASE']
        yield
        ActiveRecord::Base.connection.disconnect!
      end
    end
  end
end
