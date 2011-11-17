module Aji
  class Queues::UpdateAccountInfo
    @queue = :refresh_info

    def self.perform run_on_all = false
      Aji.log "Updating info for Youtube accounts."

      offset = Aji.redis.get("update_youtube_info:offset").to_i
      limit = 1000

      Aji::Account::Youtube.order(:id).offset(offset).limit(1000).each do |a|
        a.background_refresh_info if run_on_all or !a.valid_info?
      end

      Aji.log "Updated Youtube accounts #{offset} - #{offset + limit}"
      Aji.redis.set("update_youtube_info:offset", offset + limit)
      Resque.enqueue Queues::UpdateAccountInfo if offset < Account::Youtube.count
    end
  end
end
