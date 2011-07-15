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
    belongs_to :author, :class_name => 'ExternalAccount'
    has_and_belongs_to_many :videos

    def links
      link_text = read_attribute(:links)
      if link_text
        link_text.split('||').map{|l| Link.new l}
      else
        []
      end
    end

    def links= value
      write_attribute(:links, value.join('||'))
    end

  end
end
