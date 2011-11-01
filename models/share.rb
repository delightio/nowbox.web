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

    def link
      #"http://#{Aji.conf['TLD']}/share/#{id}"

      # Using source link during beta-testing phase.
      video.source_link
    end
  end
end

