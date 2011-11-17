module Aji
  # ## Share Schema
  # - id: Integer
  # - message: Text
  # - user_id: Integer (Foreign Key)
  # - video_id: Integer (Foreign Key)
  # - channel_id: Integer (Foreign Key)
  # - event_id: Integer (Foreign Key)
  # - network: String
  class Share < ActiveRecord::Base
    NETWORKS = ["twitter", "facebook"]

    belongs_to :user
    belongs_to :video
    belongs_to :channel
    belongs_to :event

    validates_presence_of :user
    validates_presence_of :video
    validates_presence_of :channel
    validates_inclusion_of :network, :in => NETWORKS

    before_create :default_message
    after_create :publish

    def link
      "http://#{Aji.conf['TLD']}/shares/#{id}"
    end

    def default_message
      self.message ||= video.title
    end

    def publisher
      user.send "#{network}_account".to_sym
    rescue
      nil
    end

    def publish
      publisher.background_publish self
    end

  end
end

