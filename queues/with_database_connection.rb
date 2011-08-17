module Aji
  module Queues
    module WithDatabaseConnection
      def after_fork_connect_to_database *args
        ActiveRecord::Base.establish_connection Aji.conf['DATABASE']
      end

      def after_perform_disconnect_db *args
        ActiveRecord::Base.connection.disconnect!
      end
    end
  end
end
