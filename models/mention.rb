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

    def initialize params={}
      super params
      link_objs = links.map do |link|
        Link.new(link)
      end
      self.links = link_objs
    end

    belongs_to :author, :class_name => 'Account'
    has_and_belongs_to_many :videos

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
        return true if count > 1
      end
      false
    end
    def mark_spam channel=nil
      author.blacklist
      videos.each { |v| v.mark_spam }
      if channel && channel.respond_to?(:pop)
        videos.each { |v| channel.pop v }
        if channel.respond_to? :pop_recent
          videos.each { |v| channel.pop_recent v }
        end
      end
    end
  end
end
