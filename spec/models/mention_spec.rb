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
      subject.save
      Aji::Mention.find(subject.id).links.should include link
    end
  end

  describe "#spam?" do
    it "identifies spam if mention's author has already mentioned the given video within the mention" do
      video = Factory :video_with_mentions
      mention = video.mentions.sample
      spammy_mention = Factory :mention,
        :author => mention.author,
        :videos => [video]
      spammy_mention.should be_spam
    end
    it "returns false for non spam " do
      video = Factory :video_with_mentions,
        :external_id => "OzVPDiy4P9I", :source => "youtube"
      mention = Factory :mention, :links => ["http://youtu.be/#{video.external_id}"]
      mention.should_not be_spam
    end
    it "caches result" do
      spammy_mention = Factory :mention,
        :author => (Factory :account),
        :videos => [(Factory :video)]
      spammy_mention.author.blacklist
      spammy_mention.author.should_receive(:blacklist).never
      spammy_mention.should be_spam
    end
  end
end
