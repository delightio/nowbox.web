module Aji
  class Queues::UpdateAccountInfo
    @queue = :update_account_info

    def self.perform
      Aji.log "Updating info for Youtube accounts."

      offset = Aji.redis.get("update_youtube_info:offset").to_i
      limit = 1000

      Aji::Account::Youtube.order(:id).offset(offset).limit(1000).each do |a|
        a.get_info_from_youtube_api
        a.save
      end

      Aji.log "Updated Youtube accounts #{offset} - #{offset + limit}"
      Aji.redis.set("update_youtube_info:offset", offset + limit)
      Resque.enqueue Queues::UpdateAccountInfo if offset < Account::Youtube.count
    end
  end
end
