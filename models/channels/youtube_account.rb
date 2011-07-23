module Aji
  module Channels
    class YoutubeAccount < Channel
      has_and_belongs_to_many :accounts,
        :class_name => 'Aji::ExternalAccounts::Youtube',
        :join_table => :youtube_youtube_channels, :foreign_key => :channel_id,
        :association_foreign_key => :account_id

      before_create :set_title
      def self.to_title accounts; accounts.map(&:uid).join ", "; end
      def set_title; self.title = title || self.class.to_title(accounts); end

      def populate args={}
        populating_lock.lock do
          return if recently_populated? && args[:must_populate].nil?
          accounts_populated_at = []
          accounts.each do |account|
            account.populate(args) if !account.recently_populated?
            accounts_populated_at << account.populated_at
          end
          self.populated_at = accounts_populated_at.sort.last # latest
          save
        end
      end
      
      def content_video_ids limit=-1
        if Aji.redis.ttl(content_zset.key)==-1
          keys = accounts.map{|a| a.content_zset.key}
          Aji.redis.zunionstore content_zset.key, keys
          Aji.redis.expire content_zset.key, content_zset_ttl
        end
        (content_zset.revrange 0, limit).map(&:to_i)
      end

      def self.find_all_by_accounts accounts
        accounts_channels = accounts.map{ |a| a.channels }
        # Perform an intersection on all the channels from given accounts
        # using Ruby's awesome Array#inject.
        matching_channels = accounts_channels.inject(&:&)
        matching_channels.find_all { |c| c.accounts.length == accounts.length }
      end
      
      def self.find_or_create_by_usernames usernames, args={}
        accounts = usernames.map { |n| 
          ExternalAccounts::Youtube.find_or_create_by_uid :uid => n }
        found = self.find_all_by_accounts accounts
        return found.first if !found.empty?
        
        populate_if_new = args[:populate_if_new]
        args.delete :populate_if_new
        args.merge! :accounts => accounts
        channel = self.create args
        channel.populate if populate_if_new
        channel
      end
      
    end
  end
end
