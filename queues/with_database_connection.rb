module Aji
  module Queues
    module WithDatabaseConnection
      def before_fork
        ActiveRecord::Base.establish_connection Aji.conf['DATABASE']
      end
    end
  end
end
