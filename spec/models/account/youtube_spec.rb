require File.expand_path("../../../spec_helper", __FILE__)

module Aji
  describe Account::Youtube do
    let(:video) do
      mock("video").tap do |v|
        v.stub :id => 7

        v.stub :published_at => 3.days.ago

        def v.populate
          yield self
        end
      end
    end

    let(:api) do
      mock "api", :uploaded_videos => [video]
    end

    subject do
      Account::Youtube.create(uid: "freddiew").tap do |a|
        a.stub :api => api
      end
    end

    it_behaves_like "any account"

    describe "#subscriber_count" do
      it "reads from the info hash" do
        subject.stub(:info).and_return("subscriber_count"=>100)
        subject.subscriber_count.should == 100
      end

      it "returns 0 if it's missing from hash" do
        subject.stub(:info).and_return({})
        subject.subscriber_count.should == 0
      end
    end

    describe "#existing?" do
      it "is false for non existing youtube account" do
        a = Account::Youtube.new :uid => "doesntexist"
        a.api.should_receive(:valid_uid?).and_return(false)
        a.should_not be_existing
      end

      it "is true for existing youtube account" do
        subject.api.should_receive(:valid_uid?).and_return(true)
        subject.should be_existing
      end
    end

    describe "#get_info_from_youtube_api" do
      let(:info_hash) { { 'username' => 'day9tv' } }
      let(:api) { stub :author_info => info_hash }

      subject do
        Account::Youtube.new(uid: 'day9tv').tap do |a|
          a.stub :api => api
        end
      end

      it "uses the youtube api to get author info" do
        subject.api.should_receive(:author_info).and_return(info_hash)
        subject.get_info_from_youtube_api
      end

      it "uses the username from the info hash if there is one" do
        expect { subject.get_info_from_youtube_api }.to(
          change{ subject.username }.to("day9tv"))
      end

      it "sets the username to the uid otherwise" do
        info_hash['username'] = ''

        subject.get_info_from_youtube_api
        subject.username.should == subject.uid
      end
    end

    describe "#forbidden_words_in_username?" do
      specify "is true for anything with VEVO/vevo at the end is bad" do
        bad_usernames = %w( VEVO JustinVEVO Justinvevo jkjljVEVO )
        bad_usernames.each do |bad_username|
          subject.should_receive(:username).and_return bad_username
          subject.should be_forbidden_words_in_username
        end
      end

      specify "is false if VEVO is at the beginning" do
        usernames = %w( JustinVEVOblah vevoblah )
        usernames.each do |username|
          subject.should_receive(:username).and_return username
          subject.should_not be_forbidden_words_in_username
        end
      end
    end

    describe "#available?" do
      before :each do
        subject.stub(:blacklisted?).and_return(false)
        subject.stub(:forbidden_words_in_username).and_return(false)
      end

      context "when account is not backlisted AND its name doesn't follow pattern" do
        it "is true" do
          subject.should be_available
        end
      end

      context "when account is blacklisted" do
        it "is false" do
          subject.stub(:blacklisted?).and_return(true)
          subject.should_not be_available
        end
      end

      context "when account's name has forbidden words" do
        it "is false" do
          subject.stub(:forbidden_words_in_username?).
            and_return(true)
          subject.should_not be_available
        end
      end

      context "when account is blacklisted and its name has forbidden words" do
        it "is false" do
          subject.stub(:blacklisted?).and_return(true)
          subject.stub(:forbidden_words_in_username?).and_return(true)
          subject.should_not be_available
        end
      end
    end

    describe "#authorized?" do
      specify "true when we have their token and secret" do
        subject.stub :credentials => { 'token' => "token", 'secret' => "shh" }

        subject.should be_authorized
      end

      specify "false when we don't have their token and secret" do
        subject.stub :credentials => {}

        subject.should_not be_authorized
      end
    end

    describe ".create_if_existing" do
      let(:uid) { "anything" }

      it "returns db copy if we have it" do
        a = Account::Youtube.create :uid=>uid
        Account::Youtube.create_if_existing(uid).should == a
      end

      it "does not create new object if given uid is invalid" do
        a = mock("account", :existing? => false)
        Account::Youtube.stub(:new).with(:uid=>uid).and_return(a)
        Account::Youtube.create_if_existing(uid).should be_nil
      end

      it "creates a new object if given uid is valid but not already in db" do
        a = mock("account", :existing? => true)
        Account::Youtube.should_receive(:find_or_create_by_uid).
          with(uid, {}).and_return(mock)
        Account::Youtube.create_if_existing uid
      end
    end

    describe "#refreshed?" do
      it "true if it has a thumbnail_uri" do
        subject.stub(:thumbnail_uri).and_return("jlkjlk")
        subject.should be_refreshed
      end

      it "false otherwise" do
        subject.stub(:thumbnail_uri).and_return("")
        subject.should_not be_refreshed
      end
    end

    describe "#refresh_info" do
      it "updates from youtube and save" do
        subject.should_receive :get_info_from_youtube_api
        subject.should_receive :save
        subject.refresh_info
      end
    end

    describe "#background_refresh_info" do
      it "enqueues to refresh info" do
        Resque.should_receive(:enqueue).
          with(Aji::Queues::RefreshChannelInfo, subject.id)
        subject.background_refresh_info
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
        subject.stub(:videos).and_return(Array.new(6,mock))
        subject.should_receive(:blacklist).once
        subject.blacklist_repeated_offender
      end
    end

    describe ".from_auth_hash" do
      subject { Account::Youtube.from_auth_hash auth_hash }
      let(:auth_hash) do
        {
          'uid' => 'NucLearsaNdWicH',
          'credentials' => { 'token' => 'sometoken', 'secret' => 'seekrit' },
          'extra' => { 'user_hash' => { 'first_name' => 'Steven!' } }
        }
      end

      context "when the account is already in the database" do
        let!(:existing) do
          Account::Youtube.create uid: "NucLearsaNdWicH",
            provider: 'youtube'
        end

        it "finds the account if it is already in the database" do
          subject.should == existing.reload
        end

        describe "uses auth_hash information for user" do
          its(:uid) { should == auth_hash['uid'].downcase }
          its(:username) { should == auth_hash['uid'] }
          its(:credentials) { should == auth_hash['credentials'] }
          its(:info) { should == auth_hash['extra']['user_hash'] }
        end
      end

      context "when the account is not in the database" do
        it "creates a new account" do
          subject.should_not be_new_record
        end

        describe "uses auth_hash information for user" do
          its(:uid) { should == auth_hash['uid'].downcase }
          its(:username) { should == auth_hash['uid'] }
          its(:credentials) { should == auth_hash['credentials'] }
          its(:info) { should == auth_hash['extra']['user_hash'] }
        end
      end
    end

    describe "#sign_in_as" do
      subject { Account::Youtube.new }
      let(:user) { stub }

      xit "starts a new youtube synchronization" do
        YoutubeSync.should_receive(:new).with(user, subject)

        subject.sign_in_as user
      end
    end
  end
end

