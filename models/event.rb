module Aji
  # ## Event Schema
  # - id: Integer
  # - type: Video or Channel
  # - user_id: Integer (Foreign Key) non-nil
  # - channel_id: Integer (Foreign Key) non-nil
  # - video_id: Integer (Foreign Key) non-nil
  # - video_start: Double
  # - video_elapsed: Double
  # - reason: String
  # - created_at: DateTime
  # - updated_at: DateTime
  class Event < ActiveRecord::Base
    def self.video_actions
      [ :view, :share, :enqueue, :dequeue, :examine, :unfavorite ]
    end

    def self.channel_actions
      [ :subscribe, :unsubscribe ]
    end

    def self.allowed_actions
      video_actions + channel_actions
    end

    validates_inclusion_of :action, :in => self.allowed_actions

    belongs_to :user
    belongs_to :video
    belongs_to :channel

    after_create :process

    scope :latest, lambda { |n=30| order('created_at desc').limit(n) }
    scope :viewed, where(:action => 'view')
    scope :subscribed, where(:action => 'subscribe')

    def action
      read_attribute(:action).to_sym
    end

    def action= value
      write_attribute(:action, value.to_s)
    end

    private
    def process
      user.process_event self

      if action == :examine
        Resque.enqueue Aji::Queues::ExamineVideo,
          { :user_id => user.id,
            :video_id => video.id,
            :channel_id => channel.id,
            :reason => reason }
      end
    end
  end
end
