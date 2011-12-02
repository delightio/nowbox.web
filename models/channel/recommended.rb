module Aji
  class Channel::Recommended < Channel
    has_one :user, :class_name => 'Aji::User',
      :foreign_key => :recommended_channel_id

    def available?
      false
    end

    def thumbnail_uri
      "http://#{Aji.conf['TLD']}/images/icons/categories/recommended.png"
    end

    def refresh_content force=false
    end

    def content_video_ids limit=0
      if Aji.redis.ttl(content_zset.key)==-1
        keys = user.subscribed_channels.map {|c| c.content_zset.key}
        Aji.redis.zunionstore content_zset.key, keys
        Aji.redis.expire content_zset.key, content_zset_ttl
      end
      (content_zset.revrange 0, (limit-1)).map(&:to_i)
    end

  end
end