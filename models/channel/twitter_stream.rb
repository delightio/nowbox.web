module Aji
  class Channel::TwitterStream < Channel

   has_one :owner, :class_name => 'Aji::Account',
     :foreign_key => :stream_channel_id

    validates_presence_of :owner

    def thumbnail_uri
      "http://#{Aji.conf['TLD']}/images/icons/twitter.png"
    end

    def description
      "Videos from #{owner.username}'s Twitter Feed"
    end

    def refresh_content force=false
      super force do |new_videos|
        owner.api.video_mentions_in_feed.each do |m|
          m.videos.each do |v|
            v.populate do |video|
              new_videos << video
              push video, m.published_at
            end
          end
        end
      end
    rescue Twitter::Unauthorized => e
      key = "Errors::RefreshContent::#{e.class}::channels"
      is_new = redis.sadd key, self.id
      Aji.log "Error refreshing #{self.class}[#{id}]: #{e.inspect}" if is_new
    end

  end
end
