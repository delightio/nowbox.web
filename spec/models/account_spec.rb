require File.expand_path("../../spec_helper", __FILE__)

module Aji
  describe Aji::Account do
    subject do
      # We tap the account to return it after pushing content to its Redis
      # Objects so we can test the cleanup code.
      Account.create(:username => "foobar", :uid => "1234").tap do |account|
        account.content_zset[1] = 1
        account.influencer_set << 1
      end
    end

    describe "#downcase_uid" do
      subject { Account.new uid: "CNN" }

      it "converts the stored uid to lower case" do
        expect { subject.downcase_uid }.to change{ subject.uid }.from(
          "CNN").to("cnn")
      end
    end

    it_behaves_like "any redis object model"

    describe ".from_param" do
      it "parses username and provider from a specialized param string" do
        param_string = "nuclearsandwich@youtube"
        Aji::Account.from_param(param_string).
          should == [ "nuclearsandwich", "youtube" ]
      end
    end

    describe "#marked_spammer?" do
      specify "true if account id is in the set of spammers" do
        Aji.redis.should_receive(:sismember).with("spammers", subject.id).
          and_return(true)

        subject.should be_marked_spammer
      end

      specify "false otherwise" do
        Aji.redis.should_receive(:sismember).with("spammers", subject.id).
          and_return(false)

        subject.should_not be_marked_spammer
      end
    end

    describe "#blacklisted_videos" do
      it "returns the previously blacklisted videos" do
        pending "#blacklisted_videos is an AR call but we should test it."
      end
    end

    describe "#blacklist_repeated_offender" do
      it "blacklists self if it has too many blacklisted videos" do
        subject.stub(:blacklisted_videos).and_return(Array.new(3, mock))
        subject.should_receive(:blacklist).once
        subject.blacklist_repeated_offender
      end
    end

    describe "#deauthorize!" do
      subject do
        Account.new(:uid => "foobar").tap do |a|
          a.credentials = { 'token' => 'sometoken', 'secret' => 'somesecret'}
          a.identity = Identity.new
          a.stub :stream_channel => stub(:destroy => true)
          a.stub :id => 1
          a.stub :mentions => [mock("mention", :destroy => true)]
        end
      end

      it "removes itself from its identity" do
        old_identity = subject.identity

        subject.deauthorize!

        subject.identity.should be_nil
        old_identity.accounts.should_not include subject
      end

      it "deletes credentials" do
        expect { subject.deauthorize! }.to change{ subject.credentials }.to({})
      end

      it "deletes mentions" do
        subject.mentions.each { |m| m.should_receive(:destroy) }

        subject.deauthorize!

        subject.mentions.should be_empty
      end

      it "empties content" do
        subject.content_zset.should_receive(:clear)

        subject.deauthorize!
      end

      it "clears influencers" do
        subject.influencer_set.should_receive(:clear)

        subject.deauthorize!
      end

      it "destroys its stream channel"do
        subject.stream_channel.should_receive(:destroy)

        subject.deauthorize!
      end
    end

    describe "case insensitive uid" do
      it "makes case sensitive finders private" do
        pending "Hide base activerecord method to protect db"

        expect{ Account.find_by_uid "anything" }.to(
          raise_error NoMethodError)
      end

      describe ".find_by_lower_uid" do
        let(:uid) { "Freddie25" }

        it "downcases its argument" do
          uid.should_receive(:downcase)

          Account.find_by_lower_uid uid
        end

        it "delegates to find_by_uid" do
          Account.should_receive(:find_by_uid).with(uid.downcase)

          Account.find_by_lower_uid uid
        end
      end

      describe ".find_or_create_by_lower_uid" do
        let(:uid) { "Freddie25" }

        it "downcases its argument" do
          uid.should_receive(:downcase)

          Account.find_or_create_by_lower_uid uid
        end

        it "delegates to find_by_uid" do
          Account.should_receive(:find_or_create_by_uid).with(
            uid.downcase, {})

            Account.find_or_create_by_lower_uid uid
        end
      end
    end
  end
end

