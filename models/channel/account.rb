module Aji
  class Channel::Account < Channel

    before_save :set_title

    has_and_belongs_to_many :accounts,
      :class_name => 'Aji::Account', :join_table => :accounts_channels,
      :foreign_key => :channel_id, :association_foreign_key => :account_id,
      :autosave => true

    def refresh_content force=false
      super force do |new_videos|
        accounts_populated_at = []
        accounts.each do |account|
          unless account.blacklisted?
            new_videos.concat account.refresh_content(force)
            accounts_populated_at << account.populated_at
          end
        end
        update_relevance_in_categories new_videos
      end
    end

    def content_video_ids limit=0
      if Aji.redis.ttl(content_zset.key)==-1
        keys = accounts.map{|a| a.content_zset.key}
        Aji.redis.zunionstore content_zset.key, keys
        Aji.redis.expire content_zset.key, content_zset_ttl
      end
      (content_zset.revrange 0, (limit-1)).map(&:to_i)
    end

    def subscriber_count
      subscriber_counts = accounts.map &:subscriber_count
      subscriber_counts.max
    end

    def thumbnail_uri
      return "http://#{Aji.conf['TLD']}/images/icons/#{title.downcase}.png" if default_listing
      accounts.first.thumbnail_uri
    end

    def self.find_all_by_accounts accounts
      # Take only the first accounts channels but reload all of them in order
      # to use them for the channel search below.
      possible_channels = accounts.map{|a| a.channels :reload}.first

      possible_channels.select do |c|
        c.accounts.length == accounts.length &&
          accounts.all? { |a| c.accounts.include? a }
      end
    end

    def self.find_or_create_by_accounts accounts, params={}, refresh=false
      c = Channel::Account.find_all_by_accounts(accounts).first ||
        Channel::Account.create(params.merge! :accounts => accounts)
      c.refresh_content if refresh
      c
    end

    def description
      accounts.map(&:description).join('\n\n')
    end

    def serializable_hash options={}
      s = super options
      h = {
        "type" => "Account::#{accounts.first.type.split('::').last}",
        "description" => description
      }
      s.merge! h
    end

    private
    def set_title
      self.title ||= "#{accounts.map(&:username).join(", ")}"
    end

  end
end

