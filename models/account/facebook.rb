module Aji
  class Account::Facebook < Account
    include Redis::Objects
    include Mixins::CanRefreshContent

    validates_presence_of :uid
    validates_uniqueness_of :uid

    def refresh_content force=false
      super force do |new_videos|

      end
    end

    def description
      info['bio']
    end

    def thumbnail_uri
      "http://graph.facebook.com/#{uid}/picture"
    end

    def profile_uri
      info['link']
    end
  end
end
