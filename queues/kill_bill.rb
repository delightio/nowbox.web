module Aji
  class User
    def unlink account
      identity.accounts.delete account
    end
  end

  class Queues::KillBill
    @queue = :kill_bill

    def self.perform
      bills_tw_uid = '274048697'
      bills_fb_uid = '100002238372309'
      bills_yt_uid = 'testnb1'

      [ Account::Twitter.find_by_uid(bills_tw_uid),
        Account::Facebook.find_by_uid(bills_fb_uid) ].each do |bill|
        bill.stream_channel.destroy unless bill.nil? or bill.stream_channel.nil?
      end

      yt = Account::Youtube.find_by_uid bills_yt_uid
      unless yt.nil?
        Aji.log "Destroying Account::Youtube[#{bills_yt_uid}]..."

        Aji.log "Removing Account::Youtube[#{yt.id}]"
        user = yt.user
        Aji.log "Can't find linked user" if user.nil?

        user.unlink yt
        yt.destroy
        if Account::Youtube.find_by_uid(bills_yt_uid).nil?
          Aji.log "Destroyed: #{bills_yt_uid}"
        else
          Aji.log "Failed to destroy"
        end
      end
    end
  end
end
