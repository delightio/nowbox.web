module Aji
  module Queues
    module WithDatabaseConnection
      def after_fork_connect_to_database *args
        ActiveRecord::Base.establish_connection Aji.conf['DATABASE']
      end
    end
  end
end
