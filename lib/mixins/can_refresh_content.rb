module Aji
  module Mixins::CanRefreshContent
    def self.included klass
      klass.lock :refreshing_content, :expiration => 10.minutes
    end

    # The `refresh_content` method pulls content into the database and stores
    # ids in a Redis ZSet specific to each object. The method takes a single
    # boolean argument `force` which can be used to force a refresh in spite of
    # a recently completed refresh. The method returns an array of the newly
    # added content.
    def refresh_content force=false
      [].tap do |new_videos|
        next unless should_refresh? or content_video_ids.count == 0 or force

        refreshing_content_lock.lock do
          # Use population strategy of subclass if presented.
          yield new_videos if block_given?

          # Update populated_at time, in this case we want to raise the error on
          # save since an object already in the database should never be invalid
          # yet we want the strategy to allow for updating of arbitrary object
          # attributes such as updating an external accounts info.
          self.populated_at = Time.now
          self.save!
        end
      end
    end
  end
end
