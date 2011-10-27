require File.expand_path("../../spec_helper", __FILE__)

module Aji
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
        it "returns unviewed videos" do
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

        it "returns videos according to descending order on score" do
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

        it "never returns blacklisted videos" do
          channel = Factory :youtube_channel_with_videos
          user = Factory :user
          video = channel.content_videos.sample
          video.blacklist
          channel.personalized_content_videos(:user=>user,
                                              :limit=>channel.content_videos.count).should_not include video
        end
      end

      context "when dealing with user channels" do
        before(:each) do
          @user = Factory :user
          @favorite_channel = @user.favorite_channel
        end

        it "returns videos in ascending order" do
          first_video = Factory :video
          event = Factory :event, :user => @user,
            :action => :share,  :video => first_video,
            :created_at => 20.seconds.ago
          second_video = Factory :video
          event = Factory :event, :user => @user,
            :action => :share,  :video => second_video,
            :created_at => Time.now
          @favorite_channel.personalized_content_videos(:user => @user).
            first.should == first_video
          @favorite_channel.personalized_content_videos(:user => @user).
            last.should == second_video
        end

        it "returns viewed videos" do
          video = Factory :video
          event = Factory :event, :user => @user,
            :action => :share,  :video => video
          @user.history_channel.content_videos.should include video
          @favorite_channel.personalized_content_videos(:user => @user).
            should include video
        end

        it "returns blacklisted videos" do
          video = Factory :video, :blacklisted_at => Time.now
          event = Factory :event, :user => @user,
            :action => :share,  :video => video
          @favorite_channel.personalized_content_videos(:user => @user).
            should include video
        end
      end
    end

    describe ".default_listing" do
      it "should return all channels marked as default" do
        expect { Factory(:youtube_channel_with_videos, :default_listing=>false) }.
          to_not change {Aji::Channel.default_listing.count }
        expect { Factory(:youtube_channel_with_videos, :default_listing=>true) }.
          to change {Aji::Channel.default_listing.count }.by(1)
      end
    end

    describe "trending" do
      it "returns the singleton trending channel" do
        Aji::Channel.trending.class.should == Aji::Channel::Trending
      end
    end

    describe "#serializable_hash" do
      it "includes video hash if :inline_videos count is positive" do
        channel = Factory :youtube_channel
        args = { :inline_videos=>3 }
        hash = channel.serializable_hash args
        hash["videos"].should have(args[:inline_videos]).videos
        hash["videos"].first["video"] ==
          channel.content_videos.first.serializable_hash
      end
    end

  end
end

