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
      accounts.map{ |a| a.influencers }.flatten
    end

    def social_channel_ids
      {}.tap do |channel_ids|
        channel_ids['facebook_channel_id'] = facebook_account.stream_channel.id if facebook_account
        #channel_ids['twitter_account'] = twitter_account.stream_channel if twitter_account
      end
    end

    def facebook_account
      accounts.where(:type => 'Aji::Account::Facebook').first
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
