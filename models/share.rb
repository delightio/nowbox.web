module Aji
  class AuthorizationValidator < ActiveModel::Validator
    def validate(record)
      publisher = record.publisher
      unless publisher.authorized?
        error_message = if publisher.has_token? then
                          "has an expired token." else
                          "has no token." end
        record.errors[:publisher] << error_message
      end
    end
  end
  
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

    validates_with AuthorizationValidator

    after_create :publish

    def link
      "http://#{Aji.conf['TLD']}/shares/#{id}"
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

