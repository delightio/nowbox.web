module Aji
  # ## Share Schema
  # - id: Integer
  # - message: Text
  # - user_id: Integer (Foreign Key)
  # - video_id: Integer (Foreign Key)
  class Share < ActiveRecord::Base
    belongs_to :user
    belongs_to :video
    has_many :external_accounts
    after_create :queue_publishing

    attr_accessor :publish_to

    def link
      "http://#{Aji.conf['TLD']}/#{id}"
    end

    def queue_publishing
      unless publish_to.empty?
        pub_accounts = user.external_accounts.find_all do |acc|
          publish_to.include? acc.provider
        end
      else
        pub_accounts = user.external_accounts
      end

      pub_accounts.each do |pub|
        Resque.enqueue PublishShare, pub.id, id
      end
    end
  end
end
