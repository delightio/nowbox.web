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
      channel = Factory :channel_with_videos
      user = Factory :user
      viewed_videos = []
      channel.content_videos.sample(10).each do |video|
        event = Factory :event, :event_type => :view, :user => user, :video => video
        viewed_videos << event.video
      end
      personalized_videos = channel.personalized_content_videos :user=>user
      viewed_videos.each do | viewed_video |
        personalized_videos.should_not include viewed_video
      end
    end
    
    it "should return videos according to descending order on score" do
      channel = Factory :trending_channel
      user = Factory :user
      videos_with_insertion_time = []
      10.times do |n|
        h = { :vid=>Factory(:video).id, :rel=>rand(1000) }
        videos_with_insertion_time << h
        channel.content_zset[h[:vid]] = h[:rel]
      end
      top_video_id = channel.content_zset.last
      last_video_id= channel.content_zset.first
      top_video_score = channel.content_zset.score top_video_id
      last_video_score= channel.content_zset.score last_video_id
      top_video_score.should >= last_video_score

      viewed_video = channel.content_videos.sample
      event = Factory :event, :event_type => :view, :user => user, :video => viewed_video
      personalized_videos = channel.personalized_content_videos :user=>user
      personalized_videos.should_not include viewed_video
      
      top_video_score = channel.content_zset.score personalized_videos.first.id
      last_video_score= channel.content_zset.score personalized_videos.last.id
      top_video_score.should >= last_video_score
    end
    
  end
end
