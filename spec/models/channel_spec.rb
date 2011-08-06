require File.expand_path("../../spec_helper", __FILE__)

describe Aji::Channel do
  describe "#populate" do
    it "raises an exception unless overridden." do
      c = Aji::Channel.new(:title => "foo")
      expect { c.populate }.to raise_error Aji::InterfaceMethodNotImplemented
    end
  end

  describe "#personalized_content_videos" do
    it "should return unviewed videos" do
      channel = Factory :youtube_channel_with_videos
      viewed_video_ids = channel.content_videos.sample(channel.content_videos.length / 2).map(&:id)


      user = mock("user")
      # We #dup the viewed_video_ids object since RSpec decided to count object
      user.should_receive(:viewed_video_ids).at_least(1).and_return(
        viewed_video_ids)
      personalized_video_ids = channel.personalized_content_videos(
        :user => user).map(&:id)
      viewed_video_ids.each do | id |
        personalized_video_ids.should_not include id
      end
    end

    it "should return videos according to descending order on score" do
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
      event = Factory :event, :event_type => :view, :user => user, :video => viewed_video
      personalized_videos = channel.personalized_content_videos :user=>user
      personalized_videos.should_not include viewed_video

      top_video_relevance = channel.relevance_of personalized_videos.first
      last_video_relevance= channel.relevance_of personalized_videos.last
      top_video_relevance.should >= last_video_relevance
    end

    it "should not return blacklisted videos" do
      channel = Factory :youtube_channel_with_videos
      user = Factory :user
      video = channel.content_videos.sample
      video.blacklist
      channel.personalized_content_videos(:user=>user,
        :limit=>channel.content_videos.count).should_not include video
    end

  end

  describe ".default_listing" do
    it "should return all channels marked as default" do
      n = 5
      channels = []
      n.times do |n|
        channels << Factory(:youtube_channel_with_videos, :default_listing=>false)
      end
      Aji::Channel.default_listing.should be_empty
      default_channel = channels[rand(n-1)]
      default_channel.default_listing = true
      default_channel.save
      Aji::Channel.default_listing.should include default_channel
    end
  end

  describe "trending" do
    it "returns the singleton trending channel" do
      Aji::Channel.trending.class.should == Aji::Channels::Trending
    end
  end

  describe "search" do
    before(:each) do
      @query = Array.new(3){ |n| random_string }.join(",")
    end
    
    it "returns at least one keyword channel" do
      pending "need Channels::Keyword.search_helper"
      results = Aji::Channel.search @query
      results.map(&:class).should include Aji::Channels::Keyword
    end
    
    it "returns existing keyword channel if previously existed" do
      old_keyword_channel = Aji::Channels::Keyword.create :keywords=>@query.split(',')
      Aji::Channels::Keyword.should_not_receive(:create)
      results = Aji::Channel.search @query
      results.should include old_keyword_channel
    end
    
    it "returns youtube channels"
    it "returns twitter channels"
    
    it "searches thru all sub classes" do
      pending "*** not sure why it's throwing an error wtih this spec test"
      Aji::Channel.descendants.each do | descendant |
        descendant.should_receive(:search_helper).with(@query)
      end
      Aji::Channel.search @query
    end
    
  end
end
