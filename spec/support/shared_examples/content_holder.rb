shared_examples_for "any content holder" do

  describe "#recently_populated?" do
    it "is true when refreshed within refresh_period" do
      subject.stub :populated_at => (subject.class.refresh_period/2).ago
      subject.should be_recently_populated
    end

    it "is false otherwise" do
      subject.stub :populated_at => (2*subject.class.refresh_period).ago
      subject.should_not be_recently_populated
    end
  end

  describe "#refresh_content(force)" do
    it "fetches videos" do
      expect { subject.refresh_content }.
        to change(subject, :content_video_ids).from([])
    end

    it "does not refresh within a short time" do
      subject.refresh_content
      expect { subject.refresh_content }.to_not change { subject.populated_at }
    end

    it "allows forced refresh" do
      subject.refresh_content
      expect { subject.refresh_content :force }.
        to change { subject.populated_at }
    end

    it "returns an array of videos no matter what" do
      first_refresh = subject.refresh_content
      forced_refresh = subject.refresh_content :force
      skipped_refresh = subject.refresh_content
      [ first_refresh, forced_refresh, skipped_refresh ].each do |videos|
        videos.should be_a_kind_of Array
        ## This is difficult to test in isolation so I want to relocate it to an
        #acceptance test.
        #videos.each do |video| video.should be_a_kind_of Aji::Video end
      end
    end

    it "marks videos populated" do
      subject.refresh_content
      subject.content_videos.each do |v|
        v.should be_populated,
          "#{v.external_id} from #{v.source} was not populated."
      end
    end

    it "waits for the lock before populating"

  end
end
