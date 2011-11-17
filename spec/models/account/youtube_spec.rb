require File.expand_path("../../../spec_helper", __FILE__)

include Aji
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

  describe "#video_upload_count" do
    it "returns the number of video uploads from the info hash" do
      subject.info['video_upload_count'] = 411

      subject.video_upload_count.should == subject.info['video_upload_count']
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
      a = Account::Youtube.create! uid: uid
      Account::Youtube.create_if_existing(uid).should == a.reload
    end

    it "does not create new object if given uid is invalid" do
      YoutubeAPI.should_receive(:api).and_return(mock(:valid_uid? => false))

      Account::Youtube.create_if_existing(uid).should be_nil
    end

    it "creates a new object if given uid is valid but not already in db" do
      YoutubeAPI.should_receive(:api).and_return(mock(:valid_uid? => true))
      Account::Youtube.should_receive(:find_or_create_by_lower_uid).
        with(uid).and_return(mock)

      Account::Youtube.create_if_existing(uid).should_not be_nil
    end
  end

  describe "#valid_info?" do
    it "true if it has a thumbnail_uri" do
      subject.stub(:thumbnail_uri).and_return("jlkjlk")
      subject.should be_valid_info
    end

    it "false when thumbnail is blank" do
      subject.stub(:thumbnail_uri).and_return("")

      subject.should_not be_valid_info
    end
  end

  describe "user action hooks" do
    let(:video) { mock "video", :source => :youtube }
    let(:channel) { mock "channel", :youtube_channel? => true }

    describe "#on_favorite" do
      it "favorites video via the youtube api" do
        api.should_receive(:add_to_favorites).with(video)

        subject.on_favorite video
      end

      it "ignores non-youtube videos" do
        video = mock "video", :source => :vimeo
        api.should_not_receive(:add_to_favorites).with(video)

        subject.on_favorite video
      end
    end

    describe "#on_unfavorite" do
      it "unfavorites the video via the youtube api" do
        api.should_receive(:remove_from_favorites).with(video)

        subject.on_unfavorite video
      end

      it "ignores non-youtube videos" do
        video = mock "video", :source => :vimeo
        api.should_not_receive(:remove_from_favorites).with(video)

        subject.on_unfavorite video
      end
    end

    describe "#on_enqueue" do
      it "adds the video to watch later via the youtube api" do
        api.should_receive(:add_to_watch_later).with(video)

        subject.on_enqueue video
      end

      it "ignores non-youtube videos" do
        video = mock "video", :source => :vimeo
        api.should_not_receive(:add_to_watch_later).with(video)

        subject.on_enqueue video
      end
    end

    describe "#on_dequeue" do
      it "removes the video from watch later via the youtube api" do
        api.should_receive(:remove_from_watch_later).with(video)

        subject.on_dequeue video
      end

      it "ignores non-youtube videos" do
        video = mock "video", :source => :vimeo
        api.should_not_receive(:remove_from_watch_later).with(video)

        subject.on_dequeue video
      end
    end

    describe "#on_subscribe" do
      it "subscribes to the channel on youtube via the youtube api" do
        api.should_receive(:subscribe_to).with(channel)

        subject.on_subscribe channel
      end

      it "ignores non-youtube channels" do
        channel = mock "channel", :youtube_channel? => false
        api.should_not_receive(:subscribe_to).with(channel)

        subject.on_subscribe channel
      end
    end

    describe "#on_unsubscribe" do
      it "unsubscribes from the channel on youtube via the youtube api" do
        api.should_receive(:unsubscribe_from).with(channel)

        subject.on_unsubscribe channel
      end

      it "ignores non-youtube channels" do
        channel = mock "channel", :youtube_channel? => false
        api.should_not_receive(:unsubscribe_from).with(channel)

        subject.on_unsubscribe channel
      end
    end
  end

  describe "#refresh_info" do
    subject do
      Account::Youtube.new do |a|
        a.stub :save => true
        a.stub :valid_info? => true
        a.stub :get_info_from_youtube_api
      end
    end

    it "updates from youtube and saves if info is valid" do
      subject.should_receive :get_info_from_youtube_api
      subject.should_receive :save

      subject.refresh_info
    end

    it "doesn't save invalid info" do
      subject.stub :valid_info? => false
      subject.should_not_receive(:save)

      subject.refresh_info
    end

    specify "true if info is valid" do
      subject.stub :valid_info? => true

      subject.refresh_info.should be_true
    end

    specify "false if the info collected was not valid" do
      subject.stub :valid_info? => false

      subject.refresh_info.should be_false
    end
  end

  describe "#background_refresh_info" do
    it "enqueues to refresh info" do
      Resque.should_receive(:enqueue).
        with(Aji::Queues::RefreshAccountInfo, subject.id)
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

  describe "#api" do
    subject { Account::Youtube.new uid: "nuclearsandwich" }
    let(:token) { "token" }
    let(:secret) { "secret" }

    it "uses the token and secret to build an oauth client when authorized" do
      subject.credentials = { 'token' => token, 'secret' => secret }
      YoutubeAPI.should_receive(:new).with(subject.uid, token, secret)

      subject.api
    end

    it "uses the user's uid for user operations when not authorized" do
      YoutubeAPI.should_receive(:new).with(subject.uid)

      subject.api
    end
  end

  describe ".from_auth_hash" do
    subject { Account::Youtube.from_auth_hash auth_hash }
    let(:auth_hash) { YOUTUBE_HASH }
    let(:data) do
      YoutubeAPI::DataGrabber.new "me", auth_hash['extra']['user_hash']
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
        its(:uid) { should == data.uid }
        its(:username) { should == data.username }
        its(:credentials) { should == auth_hash['credentials'] }
        its(:info) { should == data.build_hash }
      end
    end

    context "when the account is not in the database" do
      it "creates a new account" do
        subject.should_not be_new_record
      end

      describe "uses auth_hash information for user" do
        its(:uid) { should == data.uid }
        its(:username) { should == data.username }
        its(:credentials) { should == auth_hash['credentials'] }
        its(:info) { should == data.build_hash }
      end
    end
  end

  describe "#authorize!" do
    subject { Account::Youtube.new }
    let(:user) { stub :id => 42 }
    let(:sync) do
      stub.tap{ |s| s.should_receive :background_synchronize! }
    end

    it "starts a new youtube synchronization" do
      YoutubeSync.should_receive(:new).with(subject).and_return(sync)

      subject.authorize! user
    end
  end
end

