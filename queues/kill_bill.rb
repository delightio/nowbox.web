module Aji
  class Queues::KillBill
    @queue = :kill_bill

    def self.perform
      bills_tw_uid = '274048697'
      bills_fb_uid = '100002238372309'

      [ Account::Twitter.find_by_uid(bills_tw_uid),
      Account::Facebook.find_by_uid(bills_fb_uid) ].each do |bill|
        bill.stream_channel.destroy unless bill.nil? or bill.stream_channel.nil?
      end
    end
  end
end
