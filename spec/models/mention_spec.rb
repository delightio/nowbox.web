require File.expand_path("../../spec_helper", __FILE__)

module Aji
  describe Aji::Mention, :unit do
    let(:author) { stub :spamming_video? => false, :blacklisted? => false }

    subject do
      Mention.new.tap do |m|
        m.links = %w[
          http://duckduckgo.com
          http://youtu.be/BHyUyJknTwE
          http://google.com
        ]
        m.stub(:author).and_return author
        m.stub(:videos).and_return [ mock("video") ]
        m.stub(:published_at).and_return 1.hour.ago
      end
    end

    describe "new mention with specified links" do
      specify "link strings are converted to Link objects" do
        subject.links.each do |link|
          link.class.should == Link
        end
      end
    end

    describe "links collection" do
      it "defaults to an empty array" do
        Mention.new.links.class.should == Array
        Mention.new.links.should be_empty
      end

      it "saves and loads like ActiveRecord" do
        link = Link.new "http://google.com"
        subject.links = [link]
        subject.save :validate => false
        Mention.find(subject.id).links.should include link
      end
    end

    describe "#spam?" do
      specify "false when non-blacklisted author mentions video once" do
        subject.should_not be_spam
      end

      specify "true when author has mentioned video before" do
        author.stub(:spamming_video?).and_return true
        subject.should be_spam
      end

      specify "true when mention is from a blacklisted author" do
        author.stub(:blacklisted?).and_return true
        subject.should be_spam
      end
    end

    describe "#mark_spam" do
      it "adds spammy mention to a redis set" do
        Aji.redis.should_receive(:sadd).with("spammy_mentions", subject.id)
        subject.mark_spam
      end
    end

    describe "#age" do
      it "returns 0 if an older time is passed in" do
        subject.age((subject.published_at - 10.seconds).to_i).should == 0
      end

      it "returns lower score for newer mention" do
        at_time_i = Time.now.to_i
        newer_relevance = subject.age(at_time_i)

        subject.stub(:published_at).and_return 2.hours.ago
        subject.age(at_time_i).should be > newer_relevance
      end

      it "returns not a number if mention is spam" do
        subject.stub(:spam?).and_return(true)
        subject.age(Time.now.to_i).should_not be_integer
      end
    end
  end
end
