require File.expand_path("../../spec_helper", __FILE__)

include Aji
describe Aji::Channel do

  subject do
    Channel.create.tap do |c|
      c.content_zset[1] = 1
      c.category_id_zset[1] = 1
    end
  end

  it_behaves_like "any redis object model"
  it_behaves_like "any featured model"

  describe "#available?" do
    it "is true by default" do
      subject.should be_available
    end
  end

  describe "#personalized_content_videos" do
    context "when dealing with fixed channels" do
      let(:blacklisted) { mock "blacklisted", :blacklisted? => true, :id => 10 }
      let(:viewed) { mock "viewed", :blacklisted? => false, :id => 20 }

      it "always returns same content regardless of viewed or blacklisted status" do
        [blacklisted, viewed].each do |v|
          Video.stub(:find_by_id).with(v.id).and_return v
        end

        fixed_channel = Channel::Fixed.create
        fixed_channel.push blacklisted, 1
        fixed_channel.push viewed, 2

        fixed_channel.personalized_content_videos(user: mock).should ==
          [blacklisted, viewed]
      end
    end

    context "when dealing with non user channels" do
      it "returns unviewed videos", :slow do
        channel = Factory :youtube_channel_with_videos
        viewed_video_ids = channel.content_videos.sample(channel.content_videos.length / 2).map(&:id)

        user = mock("user")
        history = mock("history")
        user.stub(:history_channel).and_return(history)
        history.stub(:content_video_ids).and_return(viewed_video_ids)
        personalized_video_ids = channel.personalized_content_videos(
          :user => user).map(&:id)
        viewed_video_ids.each do | id |
          personalized_video_ids.should_not include id
        end
      end

      it "returns viewed videos when asked", :slow do
        channel = Factory :youtube_channel_with_videos
        viewed_video_ids = channel.content_videos.sample(channel.content_videos.length / 2).map(&:id)

        user = mock("user")
        history = mock("history")
        user.stub(:history_channel).and_return(history)
        history.stub(:content_video_ids).and_return(viewed_video_ids)
        personalized_video_ids = channel.personalized_content_videos(
          :user => user, :include_viewed => true).map(&:id)
        viewed_video_ids.each do | id |
          personalized_video_ids.should include id
        end
      end

      it "returns videos according to descending order on score", :slow do
        channel = Factory :channel
        10.times do |n|
          channel.push Factory(:video), rand(1000)
        end
        top_video  = channel.content_videos.first
        last_video = channel.content_videos.last
        top_video_relevance = channel.relevance_of top_video
        last_video_relevance= channel.relevance_of last_video
        top_video_relevance.should >= last_video_relevance

        viewed_video = channel.content_videos.sample
        user = Factory :user
        event = Factory :event, :action => :view, :user => user, :video => viewed_video
        personalized_videos = channel.personalized_content_videos :user=>user
        personalized_videos.should_not include viewed_video

        top_video_relevance = channel.relevance_of personalized_videos.first
        last_video_relevance= channel.relevance_of personalized_videos.last
        top_video_relevance.should >= last_video_relevance
      end

      it "never returns blacklisted videos", :slow do
        channel = Factory :youtube_channel_with_videos
        user = Factory :user
        video = channel.content_videos.sample
        video.blacklist
        channel.personalized_content_videos(:user=>user,
                                            :limit=>channel.content_videos.count).should_not include video
      end

      it "respects max_id and returns videos that rank lower than max_id" do
        ch = Factory :single_youtube_account_channel
        videos = ch.content_videos
        max_video = videos[videos.size/2]
        expected = videos[videos.size/2+1 .. -1]

        ch.personalized_content_videos(:user => (Factory :user),
                                       :max_id => max_video.id).should == expected
      end

      it "respects since_id and returns videos that rank higher than since_id" do
        ch = Factory :single_youtube_account_channel
        videos = ch.content_videos
        min_video = videos[videos.size/2]
        expected = videos[0..videos.size/2-1]

        ch.personalized_content_videos(:user => (Factory :user),
                                       :since_id => min_video.id).should == expected
      end

      context "when since_id or max_id is not found" do
        let(:channel) { Factory :single_youtube_account_channel }
        let(:missing_id) { videos = channel.content_videos
                           ((1..20).to_a - (videos.map &:id)).sample }

        it "throws an error when since_id is not found" do
          lambda { channel.personalized_content_videos(
                      :user => (Factory :user),
                      :since_id => missing_id)}.
            should throw_symbol :missing_video_id
        end

        it "returns empty lsit when max_id is not found" do
          lambda { channel.personalized_content_videos(
                      :user => (Factory :user),
                      :max_id => missing_id)}.
            should throw_symbol :missing_video_id
        end
      end
    end

    context "when dealing with user channels" do
      before(:each) do
        @user = Factory :user
        @favorite_channel = @user.favorite_channel
      end

      it "returns viewed videos" do
        video = Factory :video
        event = Factory :event, :user => @user,
          :action => :favorite,  :video => video
        @user.history_channel.content_videos.should include video
        @favorite_channel.personalized_content_videos(:user => @user).
          should include video
      end
    end
  end

  describe ".default_listing" do
    it "should return all channels marked as default", :slow do
      expect { Factory(:youtube_channel_with_videos, :default_listing=>false) }.
        to_not change {Aji::Channel.default_listing.count }
      expect { Factory(:youtube_channel_with_videos, :default_listing=>true) }.
        to change {Aji::Channel.default_listing.count }.by(1)
    end
  end

  describe ".trending" do
    it "returns the singleton trending channel" do
      Aji::Channel.trending.class.should == Aji::Channel::Trending
    end
  end

  describe "#serializable_hash" do
    it "includes video hash if :inline_videos count is positive", :slow do
      channel = Factory :youtube_channel
      args = { :inline_videos=>3 }
      hash = channel.serializable_hash args
      hash["videos"].should have(args[:inline_videos]).videos
      hash["videos"].first["video"] ==
        channel.content_videos.first.serializable_hash
    end
  end

  describe "#youtube_channel?" do
    specify "true when it is a channel with a single youtube account" do
      Channel::Account.new(accounts: [Account::Youtube.new]).
        should be_youtube_channel
    end

    specify "false when it is not a channel with a single youtube account" do
      Channel.new.should_not be_youtube_channel
      Channel::Account.new(accounts: [Account::Youtube.new,
        Account::Twitter.new]).should_not be_youtube_channel
    end
  end

  describe "#time_limited_refresh_content" do
    context "when timed out" do
      before :each do
        Timeout.should_receive(:timeout).and_return do
          raise
        end
      end

      it "does not throw exception when timed out" do
        expect { subject.time_limited_refresh_content }.
          to_not raise_error
      end

      it "returns whatever we cache if timed out" do
        expect { subject.time_limited_refresh_content }.
          to_not change { subject.content_video_ids }
      end

      it "calls background_refresh_content when timed out" do
        subject.should_receive(:background_refresh_content)

        subject.time_limited_refresh_content
      end
    end

    it "times out if refresh_content takes too long" do
      Channel.stub :refresh_content_time_limit => 1.seconds
      subject.should_receive(:refresh_content).
        and_return do
          sleep 2.seconds
          subject.content_zset[2] = 10
        end

      expect { subject.time_limited_refresh_content }.
        to_not change { subject.content_video_ids }
    end
  end

  describe "#background_refresh_content" do
    it "enqueues the channel for refresh in Resque" do
      Resque.should_receive(:enqueue).with(Queues::RefreshChannel, subject.id)

      subject.background_refresh_content
    end

    it "delays enqueueing if a time in seconds is given" do
      Resque.should_receive(:enqueue_in).with(1.hour, Queues::RefreshChannel,
                                              subject.id)

      subject.background_refresh_content 1.hour
    end
  end
end

