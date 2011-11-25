module Aji
  class Channel::Recommended < Channel

    has_and_belongs_to_many :accounts,
      :class_name => 'Aji::Account', :join_table => :accounts_channels,
      :foreign_key => :channel_id, :association_foreign_key => :account_id,
      :autosave => true

    def add_channel channel
      return unless channel.youtube_channel?
      accounts << channel.accounts.first
    end

    def remove_channel channel
      return unless channel.youtube_channel?
      accounts.delete channel.accounts.first
    end

    def available?
      false
    end

    # From Channel::Accounts ---------------------------------------------

    def refresh_content force=false
      # We are only showing the latest videos from subscribed channels
    end

    # Straight from Channel::Accounts
    def content_video_ids limit=0
      if Aji.redis.ttl(content_zset.key)==-1
        keys = accounts.map{|a| a.content_zset.key}
        Aji.redis.zunionstore content_zset.key, keys
        Aji.redis.expire content_zset.key, content_zset_ttl
      end
      (content_zset.revrange 0, (limit-1)).map(&:to_i)
    end


    def thumbnail_uri # TODO: temp icon
      return "http://#{Aji.conf['TLD']}/images/icons/nowpopular.png"
    end

    def video_count
      if accounts.all? { |a| a.provider == 'youtube' }
        accounts.map(&:video_upload_count).inject(&:+)
      else
        accounts.map { |a| a.content_videos.count }.inject(&:+)
      end
    end

    def serializable_hash options={}
      s = super options
      h = {
        "type" => "Account::#{accounts.first.type.split('::').last}",
        "video_count" => video_count,
      }
      s.merge! h
    end

  end
end

