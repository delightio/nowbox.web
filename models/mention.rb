module Aji
  # Mention Schema
  # - id: Integer
  # - author_id: Integer (Foreign Key: ExternalAccount)
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

    belongs_to :author, :class_name => 'ExternalAccount'
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

    def spam?
      return true if author.blacklisted?
      videos.each do |video|
        mentioners = video.latest_mentioners
        if mentioners.include? author
          author.blacklist
          return true
        end
      end
      false
    end
  end
end
