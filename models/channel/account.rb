module Aji
  class Channel::Account < Channel

    before_save :set_title

    has_and_belongs_to_many :accounts,
      :class_name => 'Aji::Account', :join_table => :accounts_channels,
      :foreign_key => :channel_id, :association_foreign_key => :account_id,
      :autosave => true

    def available?
      accounts.any? {|a| a.available?}
    end

    def refresh_content force=false
      super force do |new_videos|
        accounts_populated_at = []
        accounts.each do |account|
          unless account.blacklisted?
            new_videos.concat account.refresh_content(force)
            accounts_populated_at << account.populated_at
          end
        end
        update_relevance_in_categories
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

    def relevance
      100 + Math.sqrt(subscriber_count)
    end

    def update_relevance_in_categories
      top_videos = content_videos(100)
      total = top_videos.count
      top_videos.map(&:category).group_by{|g| g}.each do |h|
        category = h.first
        count = h.last.count
        unless category.nil?
          relevance_in_category = relevance * count / total
          category.update_channel_relevance self, relevance_in_category
          category_id_zset[category.id] = count
        end
      end
    end

    def most_significant_account
      sorted = accounts.sort {|x,y| y.subscriber_count <=> x.subscriber_count}
      sorted.first
    end

    def subscriber_count
      most_significant_account.subscriber_count
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
      return accounts.first.description if accounts.count==1
      "Curated channel containing videos from: #{accounts.map(&:title).join(', ')}"
    end

    def serializable_hash options={}
      s = super options
      h = {
        "type" => "Account::#{accounts.first.type.split('::').last}",
        "description" => description
      }
      s.merge! h
    end

    def set_title
      self.title ||= "#{accounts.map(&:username).join(", ")}"
    end
    private :set_title

  end
end

