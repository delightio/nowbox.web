require File.expand_path("../../spec_helper", __FILE__)

describe Aji::Mention do
  describe "new mention with specified links" do
    subject do
      Aji::Mention.new(
        :links => [ "http://duckduckgo.com", "http://google.com" ])
    end

    specify "link strings are converted to Link objects" do
      subject.links.each do |link|
        link.class.should == Aji::Link
      end
    end
  end

  describe "links collection" do
    it "defaults to an empty array" do
      subject.links.class.should == Array
      subject.links.should be_empty
    end

    it "saves and loads like ActiveRecord" do
      link = Aji::Link.new "http://google.com"
      subject.links = [link]
      subject.save :validate => false
      Aji::Mention.find(subject.id).links.should include link
    end
  end

  describe "#spam?" do
    it "returns false if the author only mentions the video once" do
      video = Factory :video_with_mentions
      video.mentions.sample.should_not be_spam
    end
    it "returns true if given mention's author mentioned the given video more than once" do
      video = Factory :video_with_mentions
      spammer = Factory :account
      spammy_mentions = video.mentions.sample(2)
      spammy_mentions.each do |m|
        m.update_attribute :author_id, spammer.id
      end
      spammy_mentions.sample.should be_spam
    end
    it "is true when mention is from a blacklisted author" do
      spammer = Factory :account, :blacklisted_at => Time.now
      spammy_mention = Factory :mention, :author => spammer
      spammy_mention.should be_spam
    end
  end

  describe "#mark_spam" do
    before(:each) do
      @video = Factory :video_with_mentions
      @spammy_mention = @video.mentions.sample
      @spammy_mention.stub(:spam?).and_return(true)
    end
    subject { @spammy_mention }
    it "blacklists its author" do
      subject.author.should_receive(:blacklist)
      subject.mark_spam
    end
    it "marks all videos mentioned spam" do
      subject.videos.each do | video |
        video.should_receive(:mark_spam)
      end
      subject.mark_spam
    end
    it "removes mentioned videos from destination channel" do
      channel = mock("channel")
      channel.stub(:respond_to?).with(:pop).and_return(true)
      channel.stub(:respond_to?).with(:pop_recent).and_return(false)
      subject.videos.each do | video |
        channel.should_receive(:pop).with(video)
      end
      subject.mark_spam channel
    end
    it "removes mentioned videos from destination channel's recent set" do
      channel = mock("channel")
      channel.stub(:respond_to?).with(:pop).and_return(true)
      channel.stub(:respond_to?).with(:pop_recent).and_return(true)
      subject.videos.each do | video |
        channel.should_receive(:pop).with(video)
        channel.should_receive(:pop_recent).with(video)
      end
      subject.mark_spam channel
    end
  end

end
