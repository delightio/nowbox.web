module Aji
  # ## Event Schema
  # - id: Integer
  # - type: Video or Channel
  # - user_id: Integer (Foreign Key) non-nil
  # - channel_id: Integer (Foreign Key) non-nil
  # - video_id: Integer (Foreign Key) non-nil
  # - video_start: Double
  # - video_elapsed: Double
  # - created_at: DateTime
  # - updated_at: DateTime
  class Event < ActiveRecord::Base
    belongs_to :user
    belongs_to :video
    belongs_to :channel
    after_create :process

    def self.video_actions; [ :view, :share, :enqueue, :dequeue, :examine ]; end
    def self.channel_actions; [ :subscribe, :unsubscribe ]; end
    
    validates_inclusion_of :action, :in => (Event.video_actions + Event.channel_actions)
    def action; read_attribute(:action).to_sym; end
    def action= value; write_attribute(:action, value.to_s); end

    private
      def process
        self.user.process_event self
        Resque.enqueue Aji::Queues::ExamineVideo, video.id if action==:examine
      end
  end
end
