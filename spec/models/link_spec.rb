require File.expand_path("../../spec_helper", __FILE__)

module Aji
  describe Aji::Link do
    describe "detecting youtube links" do
      it "detects long youtube watch links" do
        link = Link.new("http://www.youtube.com/watch?v=3307vMsCG0I")
        link.type.should == 'youtube'
        link.external_id.should == '3307vMsCG0I'
      end

      it "detects long youtube /v/ links" do
        link = Link.new("http://www.youtube.com/v/CGqx-IXckK4")
        link.type.should == 'youtube'
        link.external_id.should == 'CGqx-IXckK4'
      end

      it "detects youtu.be links" do
        link = Link.new("http://youtu.be/-iAUwamHTM4")
        link.type.should == 'youtube'
        link.external_id.should == '-iAUwamHTM4'
      end
    end

    it "detects vimeo links" do
      pending
      link = Link.new("http://vimeo.com/4937580")
      link.type.should == 'vimeo'
      link.external_id.should == '4937580'
    end

    it "can tell videos apart from other links" do
      Link.new("http://www.youtube.com/watch?v=-iAUwamHTM4&feature=youtu.be").
        should be_video
      pending
      Link.new("http://vimeo.com/4937580").should be_video
    end

    it "detects invalid links" do
      Link.new("ht:/fhqwhgads").should be_invalid
    end

    it "detects shortened links"

    context "when the link is not for a video" do
      subject { Link.new "http://duckduckgo.com" }
      specify "#external_id is nil" do
        subject.external_id.should be_nil
      end
      specify "#type is nil" do
        subject.type.should be_nil
      end
    end

    context "when the link does point to a video" do
      context "when the video is from youtube" do
        subject { Link.new "https://www.youtube.com/watch?v=vPUE4Fo4RCc" }
        specify "external_id should be a valid youtube id" do
          subject.external_id.should =~ /[-_\w]{11}/
        end

        specify "it's type is 'youtube'" do
          subject.type.should == 'youtube'
        end
      end

      context "when the video is from vimeo" do
        subject { Link.new "http://vimeo.com/394564" }
        specify "external_id should be a valid vimeo id" do
          pending
          subject.external_id.should =~ /\d+/
        end

        specify "it's type is 'vimeo'" do
          pending
          subject.type.should == 'vimeo'
        end
      end
    end

    describe "#to_video" do
      it "returns a video object for video links" do
        Link.new("https://www.youtube.com/watch?v=vPUE4Fo4RCc").to_video.
          class.should == Video
      end

      it "returns a video from the database if a matching one exists" do
        # Create the matching video
        in_database_video = Video.create :external_id => "vPUE4Fo4RCc",
          :source => 'youtube'
        Link.new("https://www.youtube.com/watch?v=vPUE4Fo4RCc").to_video.
          should == in_database_video
      end

      it "does not save new videos to the database" do
        expect { Link.new("https://www.youtube.com/watch?v=vPUE4Fo4RCc").
          to_video }.to change(Video, :count).by(0)

      end
    end
  end
end
