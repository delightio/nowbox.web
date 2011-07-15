require File.expand_path("../../spec_helper", __FILE__)

describe Aji::Video do
  subject { Aji::Video.new }

  it "validates the presence of a source"
  it "validates the presence of an external_id"

  describe "#thumbnail_uri" do
    it "should be a youtube uri when source is youtube" do
      video = Aji::Video.new :source => 'youtube', :external_id => "someID12345"
      video.thumbnail_uri.should =~ %r<^http://img\.youtube\.com/vi/>
    end

    it "should give a valid vimeo thumbnail when the source is vimeo"
  end

  describe "#populate" do
    context "when populating a youtube video" do
      subject do
        Aji::Video.new :source => 'youtube', :external_id => 'OzVPDiy4P9I'
      end

      specify "new videos are not populated on creation" do
        subject.should_not be_populated
        subject.title.should be_nil
      end

      specify "videos should have a title and description after #populating" do
        subject.populate
        subject.should be_populated
        subject.title.should_not be_nil
        subject.description.should_not be_nil
        subject.author.should_not be_nil
      end
    end

    context "when populating a vimeo video" do
      subject do
        Aji::Video.new :source => 'vimeo', :external_id => '6968393'
      end

      specify "new videos are not populated on creation" do
        subject.should_not be_populated
        subject.title.should be_nil
      end

      specify "videos should have a title and description after #populating" do
        subject.populate
        subject.should be_populated
        subject.title.should_not be_nil
        subject.description.should_not be_nil
        subject.author.should_not be_nil
      end
    end
  end

  describe "#relevance" do
    context "two videos with different mention counts" do
      specify "The video with more mentions is more relevant"
    end
   context "two videos with equal mention counts" do
      specify "The video with more recent mentions is more relevant"
   end

   it "should not consider blacklisted author" do
     at_time_i = Time.now.to_i
     video = Factory :video_with_mentions
     old_relevance = video.relevance at_time_i

     Aji::ExternalAccount.blacklist_id video.mentions.sample.author.id
     video.relevance(at_time_i).should < old_relevance
   end
  end
end

