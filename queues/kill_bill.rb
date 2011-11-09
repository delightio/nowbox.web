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
      bills_yt_uid = 'nowmovnowbox'

      [ Account::Twitter.find_by_uid(bills_tw_uid),
        Account::Facebook.find_by_uid(bills_fb_uid) ].each do |bill|
        Aji.log "Destroying #{bill.class}[#{bill.id}]..."
        bill.stream_channel.destroy unless bill.nil? or bill.stream_channel.nil?
      end

      yt = Account::Youtube.find_by_uid bills_yt_uid
      unless yt.nil?
        Aji.log "Removing Account::Youtube[#{yt.id}]"
        user = yt.user
        Aji.log "Can't find linked user" if user.nil?

        user.unlink yt
        yt.destroy
      end
    end
  end
end
