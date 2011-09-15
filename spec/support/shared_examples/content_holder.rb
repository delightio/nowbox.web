shared_examples_for "any content holder" do
  describe "refresh_content(force)" do
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
        videos.each do |video| video.should be_a_kind_of Aji::Video end
      end
    end

    it "marks videos populated" do
      subject.refresh_content
      subject.content_videos.each {|v| v.should be_populated }
    end

    it "waits for the lock before populating"

  end
end
