module Aji
  # Mention Schema
  # - id: Integer
  # - author_id: Integer (Foreign Key: Account)
  # - body: Text
  # - external_id: Integer?
  # - unparsed_data: Text
  # - published_at: DateTime
  # - links: Text (serialized to array of Link models)
  class Mention < ActiveRecord::Base
    belongs_to :author, :class_name => 'Account'
    has_and_belongs_to_many :videos
    after_initialize :initialize_links

    validates_presence_of :author

    def links
      @links ||= if self[:links]
                   self[:links].split('||').map{|l| Link.new l}
                 else
                   []
                 end
    end

    def links= value
      @links = value
      self[:links] = value.join('||')
    end

    def has_links?
      links.length > 0
    end

    # Note: Client is responsible for dealing w/ spam mentions
    def spam?
      return true if author.blacklisted?
      videos.each do |video|
        count = video.latest_mentioners.select{ |a| a==author }.count
        return true if count > 2
      end
      false
    end

    def mark_spam
      Aji.redis.sadd "spammy_mentions", id
    end

    # age from give time in seconds
    def age from_time_i
      return Float::NAN if spam?
      diff = from_time_i - published_at.to_i
      diff = 0 if diff < 0
      diff
    end

    private
    def initialize_links
      self.links= links.map { |link| Link.new(link) }
    end
  end
end
