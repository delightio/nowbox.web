module Aji
  class Channel::Account < Channel
    before_save :set_title

    has_and_belongs_to_many :accounts,
      :class_name => 'Aji::Account', :join_table => :accounts_channels,
      :foreign_key => :channel_id, :association_foreign_key => :account_id,
      :autosave => true


    def refresh_content force=false
      new_videos = []
      refresh_lock.lock do
        accounts_populated_at = []
        accounts.each do |account|
          unless account.blacklisted?
            new_videos += account.refresh_content(force)
            accounts_populated_at << account.populated_at
          end
        end
        # NOTE: Steven! thinks this should either be the current time or the
        # oldest time since it will indicate the staleness of the channel
        # better.
        unless new_videos.empty?
          update_attribute :populated_at, accounts_populated_at.sort.last # latest
        end
      end
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
      return "http://beta.#{Aji.conf['TLD']}/images/icons/#{title.downcase}.png" if default_listing
      accounts.first.thumbnail_uri
    end

    def self.find_all_by_accounts accounts
      # Take only the first accounts channels but reload all of them in order
      # to use them for the channel search below.
      possible_channels = accounts.map{|a| a.channels :reload}.first

      possible_channels.select do |c|
        c.accounts.length == accounts.length &&
          accounts.inject(true) do |bool, account|
            bool &&= c.accounts.include? account
          end
      end
    end

    def self.find_or_create_by_accounts accounts, params={}, refresh=false
      c = Channel::Account.find_all_by_accounts(accounts).first ||
        Channel::Account.create(params.merge! :accounts => accounts)
      c.refresh_content if refresh
      c
    end

    def serializable_hash options={}
      s = super options
      s.merge! "type" => "Account::#{accounts.first.type.split('::').last}"
    end

    def self.searchable_columns; [:title]; end

    private
    def set_title
      self.title ||= "#{accounts.map(&:username).join(", ")}"
    end

  end
end

