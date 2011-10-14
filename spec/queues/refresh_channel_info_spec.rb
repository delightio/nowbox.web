require File.expand_path("../../spec_helper", __FILE__)

module Aji
  describe Queues::RefreshChannelInfo do
    subject { Queues::RefreshChannelInfo }

    describe ".perform" do
      before :each do
        @channel = Channel::Account.new
        @channel.save :validate => false
        Channel.stub(:find_by_id).with(@channel.id).and_return(@channel)
        @account = mock "account", :class => Account::Youtube, :id =>1, :refreshed? => false
        @channel.stub(:accounts).and_return([@account])
      end

      it "only works with Channel::Account" do
        @channel.stub(:class).and_return(Channel)
        @channel.should_not_receive(:accounts)
        subject.perform @channel.id
      end

      it "only works with Account::Youtube" do
        @account.stub(:class).and_return(Account)
        @account.should_not_receive(:refresh_info)
        subject.perform @channel.id
      end

      it "calls Account::Youtube#refresh_info if accounts weren't refreshed" do
        @account.should_receive(:refresh_info)
        subject.perform @channel.id
      end

      it "skips if accounts are all refreshed." do
        @account.stub(:refreshed?).and_return(true)
        @account.should_not_receive(:refresh_info)
        subject.perform @channel.id
      end

    end
  end
end
