module Aji
  class Identity < ActiveRecord::Base
    has_many :accounts, :class_name => 'Aji::Account'
    has_one :user, :class_name => 'Aji::User', :dependent => :destroy
    belongs_to :graph_channel, :class_name => 'Aji::Channel'

    def merge! other
      user.merge! other.user
      other.accounts.each do |a|
        accounts << a unless accounts.include? a
      end

      other.destroy
    end

    def social_channel_ids
      {}.tap do |channel_ids|
        channel_ids['facebook_channel_id'] =
          facebook_account.stream_channel_id if facebook_account
        channel_ids['twitter_channel_id'] =
          twitter_account.stream_channel_id if twitter_account
      end
    end

    def social_channels
      accounts.map{ |a| a.stream_channel }.compact
    end

    def facebook_account
      accounts.where(:type => 'Aji::Account::Facebook').first
    end

    def twitter_account
      accounts.where(:type => 'Aji::Account::Twitter').first
    end
  end
end
