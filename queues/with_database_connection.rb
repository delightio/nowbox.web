module Aji
  module Queues
    module WithDatabaseConnection
      def self.around_perform
        Aji.log "Connecting to Database"
        ActiveRecord::Base.establish_connection Aji.conf['DATABASE']
        yield
        Aji.log "Closing connection to Database"
        ActiveRecord::Base.connection.disconnect!
        Aji.log "Database connection closed"
      end
    end
  end
end
