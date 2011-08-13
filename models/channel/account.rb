module Aji
  class Channel::Account < Channel

    has_and_belongs_to_many :accounts,
      :class_name => 'Aji::Account',
      :join_table => :accounts_channels, :foreign_key => :channel_id,
      :association_foreign_key => :account_id

    before_save :set_title

    def refresh_content force=false
      start = Time.now
      new_videos = []
      refresh_lock.lock do
        return if recently_populated? && content_video_ids.count > 0 && !force
        accounts_populated_at = []
        accounts.each do |account|
          new_videos += account.refresh_content force
          accounts_populated_at << account.populated_at
        end
        # NOTE: Steven! thinks this should either be the current time or the
        # oldest time since it will indicate the staleness of the channel
        # better.
        update_attribute :populated_at, accounts_populated_at.sort.last # latest
      end
      Aji.log :INFO, "Channel::Account[#{id}, '#{title}', #{accounts.count} accounts]#refresh_content(force:#{force}) took #{Time.now-start} s."
      update_relevance_in_categories new_videos
      new_videos
    end

    def content_video_ids limit=-1
      if Aji.redis.ttl(content_zset.key)==-1
        keys = accounts.map{|a| a.content_zset.key}
        Aji.redis.zunionstore content_zset.key, keys
        Aji.redis.expire content_zset.key, content_zset_ttl
      end
      (content_zset.revrange 0, limit).map(&:to_i)
    end

    def thumbnail_uri
      return "http://beta.#{Aji.conf['TLD']}/images/icons/icon-set_#{title.downcase}.png" if default_listing
      # accounts.sort_by(&:populated_at).last.thumbnail_uri
      accounts.first.thumbnail_uri
    end

    def self.find_all_by_accounts accounts
      accounts_channels = accounts.map{ |a| a.channels }
      # Perform an intersection on all the channels from given accounts
      # using Ruby's awesome Array#inject.
      matching_channels = accounts_channels.inject(&:&)
      matching_channels.find_all { |c| c.accounts.length == accounts.length }
    end

    # TODO: Refactor to use accounts instead of usernames in order to reduce
    # coupling. You may wine but this is what Ruby is for. Listen to your tests.
    # Also, it this is broken by your removal of provider.
    def self.find_or_create_by_accounts accounts, params={}, refresh=false
      result = Channel::Account.find_all_by_accounts accounts
      return result.first unless result.empty?

      # We have to create the channel
      channel = Channel::Account.create params
      channel.update_attribute :accounts, accounts
      channel.refresh_content if refresh
      channel
    end

    def self.searchable_columns; [:title]; end

    private
    def set_title
      self.title = "#{accounts.map(&:username).join("'s, ")}'s Videos"
    end
  end
end

