require File.expand_path("../../spec_helper", __FILE__)

module Aji
  describe Aji::Video, :unit do
    let :api do
      mock(:api).tap do |api|
        api.stub(:video_info).and_return(:title => 'A Video',
        :external_id => 'afakevideo1', :description => 'Hilarious video',
        :duration => 1024, :viewable_mobile => true, :view_count => 11,
        :source => 'youtube', :published_at => Time.now,
        :populated_at => Time.now, :author => Account.new(uid: "bob"),
        :category => Category.new)
      end
    end

    subject do
      Video.new(:source => :youtube, :external_id => 'afakevideo1').tap do |v|
        v.stub :api => api
        v.id = 42
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

      context "when given a block" do
        it "it calls the block on successful population" do
          null = stub.as_null_object
          null.should_receive :success!
          subject.populate { |v| null.success! }
        end

        it "it doesn't call the block when population fails" do
          null = stub.as_null_object
          null.should_not_receive :success!
          api.stub(:video_info) { raise Aji::VideoAPI::Error }
          subject.populate { |v| null.success! }
        end

        it "does not re populate nor update populated_at if already populated" do
          subject.populate
          ts = 30.minutes.ago
          subject.update_attribute :populated_at, ts
          null = stub.as_null_object
          null.should_receive :success!
          subject.should_receive(:api).never
          subject.populate { |v| null.success! }
          subject.populated_at.should == ts
        end
      end

      context "when a video id is invalid" do
        before :each do
          api.stub(:video_info) { raise Aji::VideoAPI::Error }
        end

        subject do
          Video.new(:external_id => 'adudosucvdd',
            :source => 'youtube').tap do |v|
              v.stub :api => api
              v.id = 42
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
          mention = mock("mention", :age=>1000)
          subject.stub_chain(:mentions, :latest).and_return([mention])
          current_relevance = subject.relevance

          old_mention = mock("mention", :age=>5000)
          subject.stub_chain(:mentions, :latest).and_return([old_mention])

          subject.relevance.should < current_relevance
        end
      end

      it "is 0 if video is blacklisted" do
        subject.stub(:blacklisted?).and_return(true)
        subject.relevance(Time.now.to_i).should == 0
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

    describe "#source_link" do
      specify "youtu.be short links for youtube videos" do
        subject.stub :source => :youtube

        subject.source_link.should == "http://youtu.be/afakevideo1"
      end

      specify "regular vimeo links for vimeo videos" do
        subject.stub :source => :vimeo

        subject.source_link.should == "http://vimeo.com/afakevideo1"
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
        subject.serializable_hash.should == { "id" => 42,
          "external_id" => "afakevideo1", "source" => 'youtube' }
      end

      it "contains many attributes when populated" do
        subject.populate
        subject.serializable_hash.keys.should == %w[id title description
          thumbnail_uri category source external_id duration view_count
          published_at author]
      end

    end

    describe "#update_or_create_by_external_id_and_source" do
      before :each do
        Video.stub(:find_or_create_by_external_id_and_source).
          and_return(subject)
      end

      it "updates for non populated video" do
        subject.stub(:populated?).and_return true
        subject.should_not_receive(:update_attributes)
        Video.update_or_create_by_external_id_and_source mock, mock, mock
      end

      it "only updates if video was not populated" do
        subject.stub(:populated?).and_return false
        subject.should_receive(:update_attributes)
        Video.update_or_create_by_external_id_and_source mock, mock, mock
      end
    end

    describe "#failed" do
      it "increases the number of failures by one" do
        expect { subject.send :failed }.to change{subject.failures.value}.by(1)
      end
    end

    describe "#api" do
      it "gets an api object from VideoAPI" do
        VideoAPI.should_receive(:for_source).with(:youtube)
        Video.new(:source => :youtube).send :api
      end
    end
  end
end
