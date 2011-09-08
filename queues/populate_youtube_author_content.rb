module Aji
  class Queues::PopulateYoutubeAuthorContent
    @queue = :populate_content

    LIMIT = 500

    def self.perform
      # If the key is unset, then it will use nil.to_i which is 0.
      offset = Aji.redis.get("populate_content:offset").to_i
      Account::Youtube.order(:id).limit(LIMIT).offset(offset).each do |account|
        unless [ 'description', 'profile_uri', 'thumbnail_uri' ].all? do |key|
            account.info.has_key? key
          end
          account.get_info_from_youtube_api
        end
        account.save
      end
      Aji.log "Populated #{LIMIT} Youtube Accounts."
      if offset + LIMIT < Account::Youtube.count
        Aji.redis.set("populate_content:offset", offset+LIMIT)
        Resque.enqueue Queues::PopulateYoutubeAuthorContent
      end
    end
  end
end
