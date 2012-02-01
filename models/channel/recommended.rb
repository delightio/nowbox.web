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

    def title
      "Recommended"
    end

    def refresh_content force=false
    end

    def content_video_ids limit=0
      if Aji.redis.ttl(content_zset.key)==-1 and user.subscribed_channels.count > 0
        keys = user.subscribed_channels.map {|c| c.content_zset.key}
        Aji.redis.zunionstore content_zset.key, keys
        Aji.redis.expire content_zset.key, content_zset_ttl

        # Re rank based on user's past events.
        (content_zset.revrange 0, 30).each do |vid|
          video = Video.find_by_id vid
          next if video.nil?
          channel = video.author.to_channel
          liked = Event.where( :user_id => user.id,
                               :channel_id => channel.id,
                               :action => [:share, :favorite]).count
          viewed = Event.where( :user_id => user.id,
                                :channel_id => channel.id,
                                :action => :view).count

          # Score is a huge number as it's seconds from epoch.
          # Use addition rather than multiplication
          bias = liked * 2.hours + viewed * 1.hours
          new_score = bias + relevance_of(video)
          push video, new_score
        end

        # Keep top 20 videos
        truncate 20
      end
      (content_zset.revrange 0, (limit-1)).map(&:to_i)
    end

    def merge! other
      other.content_zset.members(:with_scores => true).each do |(vid,score)|
        content_zset[vid] = score
      end

      other.category_id_zset.members(:with_scores => true).each do |(cid,score)|
        category_id_zset[cid] = score
      end

      other.events.each do |ev|
        events << ev
      end

      save
    end

  end
end