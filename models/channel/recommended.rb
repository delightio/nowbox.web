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

    def bias video, user
      channel = video.author.to_channel

      @cached_bias ||= Hash.new
      if @cached_bias[channel.id]
        liked = @cached_bias[channel.id]
      else
        liked = Event.where( :user_id => user.id,
                             :channel_id => channel.id,
                             :action => [:share, :favorite, :view] ).count
        @cached_bias[channel.id] = liked
      end

      liked * 1.hours
    end

    def refresh_content force=false
      if force or (Aji.redis.ttl(content_zset.key)==-1 and
                   user.subscribed_channels.count>0)
        keys = user.subscribed_channels.map {|c| c.content_zset.key}
        Aji.redis.zunionstore content_zset.key, keys
        Aji.redis.expire content_zset.key, content_zset_ttl

        # Re rank based on user's past events.
        (content_zset.revrange 0, 30).each do |vid|
          video = Video.find_by_id vid
          next if video.nil?

          # Score is a huge number as it's seconds from epoch.
          # Use addition rather than multiplication
          push video, relevance_of(video) + bias(video,user)
        end

        # Keep top 20 videos
        truncate 20
      end
    end

    def content_video_ids limit=0, start=0
      refresh_content
      (content_zset.revrange start, (start+limit-1)).map(&:to_i)
    end

    def content_video_ids_rev limit=0, start=0
      refresh_content
      (content_zset.range start, (start+limit-1)).map(&:to_i)
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