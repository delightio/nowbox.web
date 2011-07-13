require File.expand_path("../../spec_helper", __FILE__)

describe Aji::Video do
  
  describe "#thumbnail_uri" do
    it "should always have a uri if source is youtube" do
      video = Factory :video, :source=>:youtube
      video.thumbnail_uri.should include "youtube"
    end
  end
  
  describe "#populate" do
    it "should not be populated unless explicitly asked" do
      video = Factory :video, :source => :youtube, :external_id => 'OzVPDiy4P9I'
      video.is_populated?.should == false
      video.title.should be_nil
      video.populate
      Aji::Video.find(video.id).is_populated?.should == true
      Aji::Video.find(video.id).title.should_not be_nil
      
    end
  end
  
  describe ".find_or_create_from_youtubeit_video" do
    it "should mark the video populated" do
      yt_video = YouTubeIt::Client.new.video_by 'OzVPDiy4P9I'
      video = Aji::Video.find_or_create_from_youtubeit_video yt_video
      Aji::Video.find(video.id).is_populated?.should == true
      Aji::Video.find(video.id).title.should_not be_nil
    end
  end
  
end

