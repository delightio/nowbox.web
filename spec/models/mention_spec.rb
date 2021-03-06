require File.expand_path("../../spec_helper", __FILE__)

module Aji
  describe Aji::Mention, :unit do
    let(:author) { stub :spamming_video? => false, :marked_spammer? => false}
    let(:video) { mock "video" }

    subject do
      Mention.new.tap do |m|
        m.links = %w[
          http://duckduckgo.com
          http://youtu.be/BHyUyJknTwE
          http://google.com
        ]
        m.stub(:author).and_return author
        m.stub(:videos).and_return [ video ]
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

    describe "has_video?" do
      specify "true when the video is mentioned" do
        subject.has_video?(video).should be_true
      end
    end

    describe "#spam?" do
      specify "false when non-spammer author mentions video once" do
        subject.should_not be_spam
      end

      specify "true when author has mentioned video before" do
        author.stub(:spamming_video?).and_return true
        subject.should be_spam
      end

      specify "true when mention is from a spammer author" do
        author.stub(:marked_spammer?).and_return true
        subject.should be_spam
      end
    end

    describe "#marked_spam?" do
      it "is true after mark_spam" do
        expect { subject.mark_spam }.
          to change { subject.marked_spam? }.
          from(false).to(true)
      end
    end

    describe "#mark_spam" do
      it "adds spammy mention to a redis set" do
        Aji.redis.should_receive(:sadd).with("spammy_mentions", subject.id)
        subject.mark_spam
      end
    end

    describe "#significance" do
      it "is 0 if it's spam" do
        subject.stub(:marked_spam?).and_return(true)
        subject.significance.should == 0
      end

      it "is +ve if it's not spam" do
        subject.significance.should > 0
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
        subject.stub(:marked_spam?).and_return(true)
        subject.age(Time.now.to_i).should_not be_integer
      end
    end

    describe "#latest" do
      it "returns a named scope returning latest mentions sorted by published date" do
        total = 5
        all_mentions = []
        (total+1).times do |n|
          m = Mention.new :published_at => n.minutes.ago
          m.save :validate => false
          all_mentions << m
        end
        oldest = all_mentions.last
        all_mentions.shuffle!

        latest = Mention.latest(total)
        latest.should have(total).mentions
        latest.should_not include oldest
      end
    end

    describe ".create_or_find_by_uid_and_source" do
      let(:uid) { "1234567" }
      let(:source) { "twitter" }
      let(:author) { Account.new uid: uid, provider: source }
      let(:attributes) { { :author => author } }

      it "tries to create the mention immediately" do
        Mention.should_receive(:create!).with(attributes.merge!(:uid => uid,
          :source => source))
        Mention.create_or_find_by_uid_and_source uid, source, attributes
      end

      it "tries to find an existing mention if create! raises an exception" do
        Mention.stub(:create!) { raise ActiveRecord::RecordInvalid }
        Mention.should_receive(:find_by_uid_and_source).with(uid, source)

        Mention.create_or_find_by_uid_and_source uid, source
      end
    end
  end
end
