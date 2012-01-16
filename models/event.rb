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
      [ :view, :share, :enqueue, :dequeue, :examine, :favorite, :unfavorite ]
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

    scope :latest, lambda { |n=10| order('created_at desc').limit(n) }

    def action
      read_attribute(:action).to_sym
    end

    def action= value
      write_attribute(:action, value.to_s)
    end

    def video_action?
      Event.video_actions.include? action
    end

    def to_s
      str = "#{created_at.age} Event[#{id}]: U[#{user.id}] #{action.to_s.ljust(11)} @ %.2f s" % video_elapsed
      str+= " V[#{video.id}]: '#{video.title.max(20)}' in" if video_action?
      str+= " Ch[#{channel.id}]: #{channel.title}"
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
