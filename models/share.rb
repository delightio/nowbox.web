module Aji
  # ## Share Schema
  # - id: Integer
  # - message: Text
  # - user_id: Integer (Foreign Key)
  # - video_id: Integer (Foreign Key)
  class Share < ActiveRecord::Base
    belongs_to :user
    belongs_to :video

    validates_presence_of :user
    validates_presence_of :video

    before_create :default_message

    def link
      #"http://#{Aji.conf['TLD']}/share/#{id}"

      # Using source link during beta-testing phase.
      video.source_link
    end

    def default_message
      self.message ||= video.title
    end

    def self.from_event event
      create! user: event.user, video: event.video, message: event.reason
    end
  end
end

