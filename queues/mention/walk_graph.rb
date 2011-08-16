# Commented out psuedocode.
#module Aji
#  class Queues::Mention::WalkGraph
#    @queue = :mention
#
#    def self.perform identity_id
#      identity = Identity.find identity_id
#
#      identity.accounts.each do |account|
#        account.refresh_generated_content
#      end
#
#      Resque.enqueue Queues::RefreshChannel, identity.channel.id
#    end
#  end
#end
