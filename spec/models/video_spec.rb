require File.expand_path("../../spec_helper", __FILE__)

describe Aji::Video do

  it "only allows unique video object to be created" do
    src = random_video_source
    eid = random_string
    v1 = Aji::Video.create :external_id => eid, :source => src
    v1.save.should be_true
    v2 = Aji::Video.find_or_create_by_external_id_and_source(eid, src)
    v2.id.should == v1.id
  end

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
      subject.should be_populated
      subject.title.should_not be_nil
      subject.author.uid.should == "nowmov"
    end

    context "when a video id is invalid" do
      subject do
       Aji::Video.new :id => 666, :external_id => 'adudosucvdd',
         :source => 'youtube'
      end

      it "marks a failure" do
        subject.should_receive :failed
        subject.populate
      end

      it "blacklists the video when failures reach the max" do
        9.times { subject.send :failed }
        subject.should_receive :blacklist
        subject.populate
      end
    end
  end

  describe "#relevance" do
    subject { Aji::Video.new(:source => :youtube,
      :external_id => random_string) }

    context "when videos have an equal number of mentions" do
      it "should return higher relevance for newer mentions" do
        mention = mock("mention")
        mention.stub(:age).with(anything()).and_return 1000
        subject.stub(:latest_mentions).and_return([mention])
        current_relevance = subject.relevance

        old_mention = mock("mention")
        old_mention.stub(:age).with(anything()).and_return 5000
        subject.stub(:latest_mentions).and_return([old_mention])
        subject.relevance.should < current_relevance
      end
    end

    it "is 0 if video is blacklisted" do
      subject.stub(:blacklisted?).and_return(true)
      subject.relevance(Time.now.to_i).should == 0
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

  describe "#latest_mentioners" do
    it "returns the latest external accounts who mentioned about the video" do
      video = Factory :video_with_mentions
      mentioners = video.mentions.map(&:author)
      Set.new(video.latest_mentioners).should == Set.new(mentioners)
    end
  end

  describe "#mark_spam" do
    subject { Factory :video }
    it "blacklists itself" do
      subject.should_receive(:blacklist)
      subject.author.should_not be_nil
      subject.author.should_receive(:blacklist)
      subject.mark_spam
    end
  end

  describe "#failed" do
    it "increases the number of failures by one" do
      subject { Video.new(:id => 777) }
      expect { subject.send :failed }.to change(subject, :failures).by(1)
    end
  end
end

