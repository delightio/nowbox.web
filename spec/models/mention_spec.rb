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

    it "marks all videos mentioned spam" do
      video = mock "video"
      video.should_receive :mark_spam
      subject.stub(:videos).and_return([video])
      subject.mark_spam
    end
  end

  describe "#age" do
    # TODO: LH #342 why can't I do the following?
    # Had to use Factory to get spec to run.
    # before :each do
    #   @author = mock('author', :blacklisted? => false)
    # end
    # subject { Aji::Mention.new :author => @author }
    subject { Factory :mention }
    it "returns 0 if an older time is passed in" do
      subject.age((subject.published_at-10.seconds).to_i).should == 0
    end
    it "returns lower score for newer mention" do
      at_time_i = Time.now.to_i
      newer_relevance = subject.age(at_time_i)
      subject.update_attribute(:published_at,
        subject.published_at-30.seconds)
      subject.age(at_time_i).should be > newer_relevance
    end
  end

end
