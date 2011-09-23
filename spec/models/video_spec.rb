require File.expand_path("../../spec_helper", __FILE__)

module Aji
  describe Aji::Video, unit: true do
    before :each do
      @api = mock "api"
      @api.stub(:video_info).and_return(:title => 'A Video',
        :external_id => 'afakevideo1', :description => 'Hilarious video',
        :duration => 1024, :viewable_mobile => true, :view_count => 11,
        :source => 'youtube', :published_at => Time.now,
        :populated_at => Time.now, :author => Account.new,
        :category => Category.new)
    end

    subject do
      Video.new(:source => :youtube, :external_id => 'afakevideo1').tap do |v|
        v.stub(:api).and_return @api
      end
    end

    describe "#thumbnail_uri" do
      it "should always have a uri if source is youtube" do
        subject.thumbnail_uri.should_not == ""
      end

      it "should return empty otherwise" do
        subject.source = :vimeo
        subject.thumbnail_uri.should == ""
      end
    end

    describe "#populate" do
      it "should not be populated unless explicitly asked" do
        subject.should_not be_populated
        subject.title.should be_nil
        subject.populate
        subject.should be_populated
        subject.title.should_not be_nil
        subject.author.should_not be_nil
      end

      context "when a video id is invalid" do
        before :each do
          @api.stub(:video_info) { raise Aji::VideoAPI::Error }
        end

        subject do
          Video.new(:id => 666, :external_id => 'adudosucvdd',
            :source => 'youtube').tap do |v|
              v.stub(:api).and_return @api
          end
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
        subject.mentions << Mention.new(:published_at => 5.minutes.ago)
        subject.mentions << Mention.new(:published_at => Time.now)
        subject.mentions << Mention.new(:published_at => 10.minutes.ago)
        oldest_mention = subject.mentions.sort_by(&:published_at).first
        subject.latest_mentions(2).should_not include oldest_mention
      end
    end

    describe "#latest_mentioners" do
      it "returns the latest external accounts who mentioned about the video" do
        mentions = mock("mentions")
        mentions.should_receive :map
        subject.stub :latest_mentions => mentions
        subject.latest_mentioners
      end
    end

    describe "#mark_spam" do
      it "blacklists itself" do
        subject.stub :author => mock('author')
        subject.should_receive(:blacklist)
        subject.author.should_receive(:blacklist)
        subject.mark_spam
      end
    end

    describe "#serializable_hash" do
      before :each do
        subject.stub(:author).and_return mock("author",
         :serializable_hash => "serial author")
        subject.stub(:category).and_return mock("category",
         :serializable_hash => "a category")
      end

      it "contains only source, external_id, and id when not populated" do
        subject.serializable_hash.should == { "id" => nil,
          "external_id" => "afakevideo1", "source" => :youtube }
      end

      it "contains many attributes when populated" do
        subject.populate
        subject.serializable_hash.keys.should == %w[id title description
          thumbnail_uri category source external_id duration view_count
          published_at author]
      end

    end

    describe "#failed" do
      it "increases the number of failures by one" do
        expect { subject.send :failed }.to change(subject, :failures).by(1)
      end
    end

    describe "#api" do
      it "gets an api object from VideoAPI" do
        VideoAPI.should_receive(:new).with(:youtube)
        Video.new(:source => :youtube).send :api
      end
    end
  end
end
