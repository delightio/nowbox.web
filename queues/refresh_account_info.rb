module Aji
  class Queues::RefreshAccountInfo
    extend Queues::WithDatabaseConnection

    @queue = :refresh_info

    def self.perform account_id
      account = Account.find account_id

      attempts = 0

      until account.refresh_info or attempts > 3
        attempts += 1
        Kernel.sleep 5
      end

      raise Aji::Error, "Can't populate account from youtube." if attempts > 3
    end
  end
end

