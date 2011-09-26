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

    it "returns true if given mention's author mentioned the given video more than twice" do
      video = Factory :video_with_mentions
      spammer = Factory :account
      spammy_mentions = video.mentions.sample(3)
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
    subject do
      Aji::Mention.new.tap do |m|
      end
    end

    it "adds spammy mention to a redis set" do
      Aji.redis.should_receive(:sadd).with("spammy_mentions", subject.id)
      subject.mark_spam
    end
  end

  describe "#age" do
    subject do
      m = Aji::Mention.new :published_at => Time.now
      m.stub(:spam?).and_return(false)
      m
    end

    it "returns 0 if an older time is passed in" do
      subject.age((subject.published_at-1.seconds).to_i).should == 0
    end

    it "returns lower score for newer mention" do
      older_mention = Aji::Mention.new(
        :published_at => subject.published_at-2.hours)
      older_mention.stub(:spam?).and_return(false)
      at_time_i = Time.now.to_i
      older_mention.age(at_time_i).should be > subject.age(at_time_i)
    end

    it "returns not a number if mention is spam" do
      subject.stub(:spam?).and_return(true)
      subject.age(Time.now.to_i).should_not be_integer
    end

  end

end
