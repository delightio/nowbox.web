require File.expand_path("../../../spec_helper", __FILE__)

module Aji
  describe Aji::Account::Twitter, :unit, do
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

    describe "#refresh_influencers" do
      xit "adds twitter followers as influencers" do
      end
    end

    describe "#mark_spammer" do
      it "marks own mentions as spam and destroys them" do
        mentions.should_receive :each
        subject.mark_spammer
      end

      it "blacklists itself" do
        subject.should_receive :blacklist
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

    describe "#create_stream_channel" do
      it "creates a channel for the account's twitter stream" do
        Channel::TwitterStream.should_receive(:create).with(:owner => subject,
          :title => "Twitter Stream").and_return(
          Channel::TwitterStream.new(:owner => subject,
            :title => "Twitter Stream"))
        subject.stub(:save => true)
        subject.create_stream_channel
      end
    end
  end
end
