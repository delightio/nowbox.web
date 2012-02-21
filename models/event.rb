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

    def self.create_channel_if_needed params
      action = params[:action] || params["action"]
      channel_id = params[:channel_id] || params["channel_id"]
      if Event.channel_actions.include?(action.to_sym) and channel_id.nil?
        source = params[:channel_source] || params["channel_source"]
        uid = params[:channel_uid] || params["channel_uid"]
        account_class = case source
          when 'twitter' then Account::Twitter
          when 'facebook' then Account::Facebook
          when 'youtube' then Account::Youtube
          end

        account = account_class.find_or_create_by_lower_uid uid.downcase
        channel = account.to_channel
        unless channel.nil?
          params[:channel_id] = channel.id
          params = params.delete_if {|k| k==:channel_source or k=="channel_source" }
          params = params.delete_if {|k| k==:channel_uid or k=="channel_uid" }
        end
      end
      params
    end

    def self.create_video_if_needed params
      action = params[:action] || params["action"]
      video_id = params[:video_id] || params["video_id"]
      if Event.video_actions.include?(action.to_sym) and video_id.nil?
        source = params[:video_source] || params["video_source"]
        external_id = params[:video_uid] || params["video_uid"]
        video = Video.find_or_create_by_source_and_external_id source, external_id
        unless video.nil?
          params[:video_id] = video.id
          params = params.delete_if {|k| k==:video_source or k=="video_source" }
          params = params.delete_if {|k| k==:video_uid or k=="video_uid" }
        end
      end
      params
    end

    def self.parse_params params
      params = create_channel_if_needed params
      params = create_video_if_needed params
    end

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
      str = "#{created_at.age}, Event[#{id}]: U[#{user.id}] #{action.to_s.ljust(11)} @ %.2f s" % video_elapsed
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