module Aji
  # ## Share Schema
  # - id: Integer
  # - message: Text
  # - user_id: Integer (Foreign Key)
  # - video_id: Integer (Foreign Key)
  # - channel_id: Integer (Foreign Key)
  # - network: String
  class Share < ActiveRecord::Base
    NETWORKS = ["twitter", "facebook"]

    belongs_to :user
    belongs_to :video
    belongs_to :channel

    validates_presence_of :user
    validates_presence_of :video
    validates_presence_of :channel
    validates_inclusion_of :network, :in => NETWORKS

    before_create :default_message

    def link
      #"http://#{Aji.conf['TLD']}/share/#{id}"

      # Using source link during beta-testing phase.
      video.source_link
    end

    def default_message
      self.message ||= video.title
    end

    def publisher
      user.send "#{network}_account".to_sym
    end

    def self.from_event event, network
      create! user: event.user,
        video: event.video, channel: event.channel,
        message: event.reason, network: network
    end
  end
end

