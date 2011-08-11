module Aji
  module Channels
    class YoutubeAccount < Channel
      has_and_belongs_to_many :accounts,
        :class_name => 'Aji::Account::Youtube',
        :join_table => :youtube_youtube_channels, :foreign_key => :channel_id,
        :association_foreign_key => :account_id

      before_create :set_title
      def self.to_title accounts; accounts.map(&:uid).join ", "; end
      def set_title; self.title = title || self.class.to_title(accounts); end

      def refresh_content force=false
        start = Time.now
        refresh_lock.lock do
          return if recently_populated? && content_video_ids.count > 0 && !force
          accounts_populated_at = []
          accounts.each do |account|
            account.refresh_content force
            accounts_populated_at << account.populated_at
          end
          # TODO: Steven! thinks this should either be the current time or the
          # oldest time since it will indicate the staleness of the channel
          # better.
          update_attribute :populated_at, accounts_populated_at.sort.last # latest
        end
        Aji.log :INFO, "Channels::YoutubeAccount[#{id}, '#{title}', #{accounts.count} accounts]#refresh_content(force:#{force}) took #{Time.now-start} s."
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

      def self.find_or_create_by_usernames usernames, params={}
        accounts = usernames.map do |n|
          Account::Youtube.find_or_create_by_uid :uid => n
        end
        found = self.find_all_by_accounts accounts
        return found.first if !found.empty?

        populate_if_new = params[:populate_if_new]
        params.delete :populate_if_new
        params.merge! :accounts => accounts
        channel = Channels::YoutubeAccount.create params
        channel.refresh_content if populate_if_new
        channel
      end

      def self.searchable_columns; [:title]; end
    end
  end
end

