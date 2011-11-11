module Aji
  class User
    def unlink account
      identity.accounts.delete account
    end
  end

  class Queues::KillChris
    @queue = :debug

    def self.perform
      tw_uid = '408090392' # ChrisNowbox
      fb_uid = '100001264467114' # Thomas Mov
      yt_uid = 'DoctorSbaitso'.downcase

      [ Account::Twitter.find_by_uid(tw_uid),
        Account::Facebook.find_by_uid(fb_uid) ].each do |bill|
        bill.stream_channel.destroy unless bill.nil? or bill.stream_channel.nil?
      end

      yt = Account::Youtube.find_by_uid yt_uid
      unless yt.nil?
        Aji.log "Destroying Account::Youtube[#{yt_uid}]..."

        Aji.log "Removing Account::Youtube[#{yt.id}]"
        user = yt.user
        Aji.log "Can't find linked user" if user.nil?

        user.unlink yt
        yt.destroy
        if Account::Youtube.find_by_uid(yt_uid).nil?
          Aji.log "Destroyed: #{yt_uid}"
        else
          Aji.log "Failed to destroy"
        end
      end
    end
  end
end
