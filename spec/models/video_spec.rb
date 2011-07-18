require File.expand_path("../../spec_helper", __FILE__)

describe Aji::Video do

  describe "#thumbnail_uri" do
    it "should always have a uri if source is youtube" do
      video = Factory :video, :source=>:youtube
      video.thumbnail_uri.should include "youtube"
    end
  end

  describe "#populate" do
    subject do
      Aji::Video.new :source => :youtube, :external_id => 'OzVPDiy4P9I'
    end

    it "should not be populated unless explicitly asked" do
      subject.should_not be_populated
      subject.title.should be_nil
      subject.populate
      Aji::Video.find(subject.id).should be_populated
      Aji::Video.find(subject.id).title.should_not be_nil
    end
  end

  describe ".find_or_create_from_youtubeit_video" do
    it "should mark the video populated" do
      yt_video = YouTubeIt::Client.new.video_by 'OzVPDiy4P9I'
      video = Aji::Video.find_or_create_from_youtubeit_video yt_video
      Aji::Video.find(video.id).should be_populated
      Aji::Video.find(video.id).title.should_not be_nil
    end
  end

  describe "#relevance" do
    it "should return higher relevance for newer mentions given the same number of mentions" do
      at_time_i = Time.now.to_i
      video = Factory :video_with_mentions
      old_relevance = video.relevance at_time_i

      # make video's mentions more recent
      video.mentions.each do |mention|
        mention.published_at = mention.published_at + rand(100).seconds
        mention.published_at = Time.now if (mention.published_at.to_i-Time.now.to_i>0)
        mention.save
      end
      video.relevance(at_time_i).should > old_relevance
    end

    it "should not consider blacklisted author" do
      at_time_i = Time.now.to_i
      video = Factory :video_with_mentions
      old_relevance = video.relevance at_time_i

      video.mentions.sample.author.blacklist
      video.relevance(at_time_i).should < old_relevance
    end
  end
  
  describe "#latest_mentions" do
    it "returns the latest N mentions" do
      video = Factory :video
      mentions =[]
      mentions << Factory(:mention, :published_at => 5.minutes.ago)
      mentions << Factory(:mention, :published_at => Time.now)
      mentions << Factory(:mention, :published_at => 10.minutes.ago)
      mentions.each { |m| m.videos << video }
      oldest_mention = mentions.sort_by(&:published_at).first
      video.mentions.count.should == 3
      video.latest_mentions(2).should_not include oldest_mention
    end
  end
end

