require File.expand_path("../../../spec_helper", __FILE__)

module Aji
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
      }).tap do |a|
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

    describe "#update_from_auth_info" do
      let(:auth_info) do
        {
          'credentials' => { 'token' => 'somesecrettoken' },
          'extra' => { 'user_hash' => {'username' => 'somescreenname'} }
        }
      end

      it "updates facebook credentials" do
        expect { subject.update_from_auth_info auth_info }.to(
          change{subject.credentials}.to(auth_info['credentials']))
      end

      it "updates the username" do
        expect { subject.update_from_auth_info auth_info }.to(
          change{subject.username}.to(
            auth_info['extra']['user_hash']['username']))
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
        Channel::FacebookStream.new(:owner => subject,
          :title => "Facebook Stream").tap do |c|
            c.stub :id => 1
            c.stub :save => true
            c.stub :refresh_content
            Channel.should_receive(:create).with(:owner => subject,
              :title => "Facebook Stream").and_return(c)
          end
      end

      it "creates a channel for the account's facebook stream" do
        subject.stub(:save => true)

        subject.create_stream_channel
      end

      it "refreshes the channel's content" do
        stream_channel.should_receive(:refresh_content)

        subject.create_stream_channel
      end
    end

    it_behaves_like "any account"
  end
end
