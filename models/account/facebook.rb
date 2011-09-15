module Aji
  class Account::Facebook < Account
    include Redis::Objects
    include Mixins::RecentVideos

    validates_presence_of :uid
    validates_uniqueness_of :uid

  end
end
