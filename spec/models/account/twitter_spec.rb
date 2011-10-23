require File.expand_path("../../../spec_helper", __FILE__)

module Aji
  describe Aji::Account::Twitter, :unit do
    let(:mentions) { stub.as_null_object }

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
      Account::Twitter.create(:uid => '178492493').tap do |a|
        a.stub :api => api
        a.stub :mentions => mentions
      end
    end

    it_behaves_like "any account"

    describe "#subscriber_count" do
      it "reads from the info hash" do
        subject.stub(:info).and_return("followers_count"=>100)
        subject.subscriber_count.should == 100
      end

      it "returns 0 if it's missing from hash" do
        subject.stub(:info).and_return({})
        subject.subscriber_count.should == 0
      end
    end

    describe "#refresh_influencers" do
      it "adds twitter followers as influencers" do
      end
    end

    describe "#mark_spammer" do
      it "marks own mentions as spam and destroys them" do
        mentions.each {|m| m.should_receive :mark_spam }
        subject.mark_spammer
      end

      it "blacklists itself" do
        subject.should_receive :blacklist
        subject.mark_spammer
      end

      it "adds itself to a redis set of spammers" do
        Aji.redis.should_receive(:sadd).with("spammers", subject.id)
        subject.mark_spammer
      end
    end

    describe "#spamming_video?" do
      specify "true when video is mentioned more than SPAM_THRESHOLD times" do
        subject.stub_chain(:mentions, :latest).and_return(
          Array.new Account::SPAM_THRESHOLD+1, stub(:has_video? => true))
        subject.spamming_video?(mock("video")).should be_true
      end

      specify "false otherwise" do
        subject.stub_chain(:mentions, :latest).and_return([stub(:has_video? => false)])
        subject.spamming_video?(mock("video")).should be_false
      end
    end

    describe "#authorized?" do
      it "is true when user has token and secret credentials" do
        subject.stub(:credentials).and_return({ 'token' => "tokenstring",
          'secret' => "secretstring" })
        subject.should be_authorized
      end

      it "is false when account has no credentials" do
        subject.stub(:credentials).and_return Hash.new
        subject.should_not be_authorized
      end
    end

    describe "#format" do
      let(:long_message) { "A really #{"long" * 15} string" }
      let(:short_message) { "Hah this video!" }
      let(:link_text) { "http://nowbox.com/share/51232" }

      it "shortens messages to less than 140 characters" do
        subject.format(long_message, link_text).length.should be < 140
        subject.format(short_message, link_text).length.should be < 140
      end

      it "includes the link text no matter the message length" do
        subject.format(long_message, link_text).should include link_text
        subject.format(short_message, link_text).should include link_text
      end

      it "includes the twitter coda" do
        coda = " #{link_text} via @nowbox for iPad"
        subject.format(long_message, link_text).should include coda
        subject.format(short_message, link_text).should include coda
      end
    end

    describe "#update_from_auth_info" do
      let(:auth_info) do
        {
          'credentials' => { 'token' => 'sometoken', 'secret' => 'somesecret'},
          'extra' => { 'user_hash' => {'screen_name' => 'somescreenname'} }
        }
      end

      it "updates twitter credentials" do
        expect { subject.update_from_auth_info auth_info }.to(
          change{subject.credentials}.to(auth_info['credentials']))
      end

      it "updates the username" do
        expect { subject.update_from_auth_info auth_info }.to(
          change{subject.username}.to(
            auth_info['extra']['user_hash']['screen_name']))
      end

      it "updates the stored info hash" do
        expect { subject.update_from_auth_info auth_info }.to(
          change{subject.info}.to(auth_info['extra']['user_hash']))
      end

      it "returns the account" do
        subject.update_from_auth_info(auth_info).should == subject
      end
    end

    describe "#create_stream_channel" do
      let!(:stream_channel) do
        Channel::TwitterStream.new(:owner => subject,
          :title => "Twitter Stream").tap do |c|
            c.stub :id => 1
            c.stub :save => true
            c.stub :refresh_content
            Channel::TwitterStream.should_receive(:create).with(
              :owner => subject, :title => subject.username).and_return(c)
          end
      end

      it "creates a channel for the account's twitter stream" do
        subject.stub(:save => true)

        subject.create_stream_channel
      end

      it "refreshes the channel's content" do
        subject.stub(:save => true)
        stream_channel.should_receive(:refresh_content)

        subject.create_stream_channel
      end
    end
  end
end
