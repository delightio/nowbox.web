module Aji
  class Identity < ActiveRecord::Base
    has_many :accounts, :class_name => 'Aji::Account'
    has_one :user, :class_name => 'Aji::User'
    belongs_to :graph_channel, :class_name => 'Aji::Channel'

    def update_graph_channel
      accounts.each do |account|
        account.refresh_influencers
        account.authorize_with_twitter! do
          account.influencers.map(&:refresh_content)
        end
      end

      if graph_channel.nil?
        graph_channel = Channel::Account.create(
          :title => "#{user.first_name}'s Social Channel",
          :accounts => influencers)
      else
        influencers.each do |i|
          graph_channel.accounts << i unless graph_channel.accounts.include? i
        end
      end

      graph_channel.refresh_content
      save
      graph_channel
    end

    def influencers
      accounts.map{ |a| a.influencers }.flatten.compact
    end

    # Identity is a model which associates multiple user accounts with the same
    #
    # person or corporation. At this time, the only way for this to happen is for
    # a user to log in and authorize us for multiple services (such as Twitter,
    # Facebook, and Youtube)

    # Identities are created whenever a user logs in. Down the road they'll also
    # be created by authors and others using our backend products.
  end
end
