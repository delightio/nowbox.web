require File.expand_path("../../../spec_helper", __FILE__)

include Aji

describe Account::Facebook, :unit do
  let(:video) do
    mock("video").tap do |v|
      v.stub :id => 7

      def v.populate
        yield self
      end
    end
  end

  let(:api) do
    mock "api", :video_mentions_i_post => [
      stub(:published_at => Time.now,
           :videos => [video]) ]
  end

  subject do
    Account::Facebook.create(:uid => "501776555", :credentials => { 'token' =>
      "AAACF78hfSZBEBAM0leS4CSzXZARd7S68Al6uVzs8DwJ8huZAm1YsjYeiZA2gBR3p7Ue8l3EPrKjkv6EtmOQuXo95aNTIcPIZD"
    }) do |a|
      a.stub :api => api
    end
  end

  describe "spamming_video?" do
    specify "true when video is mentioned more than SPAM_THRESHOLD times" do
      subject.stub_chain(:mentions, :latest).and_return(
        Array.new Account::SPAM_THRESHOLD+1, stub(:has_video? => true))
        subject.spamming_video?(mock("video")).should be_true
    end

    specify "false otherwise" do
      subject.stub_chain(:mentions, :latest).and_return(
        [stub(:has_video? => false)])
        subject.spamming_video?(mock("video")).should be_false
    end
  end

  describe "#build_stream_channel" do
    let!(:stream_channel) do
      Channel::FacebookStream.new(:owner => subject,
        :title => "Facebook Stream").tap do |c|
          c.stub :id => 1
          c.stub :save => true
          c.stub :refresh_content
          Channel.should_receive(:create).with(:owner => subject,
           :title => subject.realname).and_return(c)
        end
    end

    it "creates a channel for the account's facebook stream" do
      subject.stub(:save => true)

      subject.build_stream_channel
    end

    it "refreshes the channel's content" do
      stream_channel.should_receive(:refresh_content)

      subject.build_stream_channel
    end
  end

  describe "#publish" do
    let(:share) { stub :message => "A message", :link => "http://link.io" }
    let(:formatted_message) { "A formatted message" }

    it "publishes the formatted share message to the twitter api" do
      subject.should_receive(:format).with(share.message, share.link).
        and_return(formatted_message)
      subject.api.should_receive(:publish).with(formatted_message)

      subject.publish share
    end
  end

  describe ".from_auth_hash" do
    subject { Account::Facebook.from_auth_hash auth_hash }

    let(:auth_hash) do
      {
        'uid' => '1075392174',
        'credentials' => { 'token' => 'sometoken' },
        'extra' => { 'user_hash' => { 'name' => 'Vienna Teng' } }
      }
    end

    context "when the account is already in the database" do
      let!(:existing) do
        Account::Facebook.create! uid: "1075392174", provider: 'facebook'
      end

      it "finds the existing account" do
        subject.should == existing.reload
      end

      describe "uses auth_hash information for user" do
        its(:username) do
          should == (auth_hash['extra']['user_hash']['username'] || "")
        end
        its(:uid) { should == auth_hash['uid'] }
        its(:credentials) { should == auth_hash['credentials'] }
        its(:info) { should == auth_hash['extra']['user_hash'] }
      end
    end

    context "when the account is not in the database" do
      it "creates a new account" do
        subject.should_not be_new_record
      end

      describe "uses auth_hash information for user" do
        its(:username) do
          should == (auth_hash['extra']['user_hash']['username'] || "")
        end
        its(:uid) { should == auth_hash['uid'] }
        its(:credentials) { should == auth_hash['credentials'] }
        its(:info) { should == auth_hash['extra']['user_hash'] }
      end
    end
  end

  it_behaves_like "any account"
end

