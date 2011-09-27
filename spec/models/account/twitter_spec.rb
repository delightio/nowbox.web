require File.expand_path("../../../spec_helper", __FILE__)

module Aji
  describe Aji::Account::Twitter, :unit, :focus do
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
      end
    end

    #it_behaves_like "any content holder"
    it_behaves_like "any redis object model"

    describe "#refresh_influencers" do
      xit "adds twitter followers as influencers" do
      end
    end

    describe "#mark_spammer" do
      let(:mentions) { stub.as_null_object }

      before do
        subject.stub(:mentions).and_return mentions
      end

      it "marks own mentions as spam and destroys them" do
        mentions.should_receive :each
        subject.mark_spammer
      end

      it "blacklists itself" do
        subject.should_receive :blacklist
        subject.mark_spammer
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
  end
end
