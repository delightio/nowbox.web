require File.expand_path("../../spec_helper", __FILE__)

describe Aji::Macker do
  describe ".fetch" do
    pending "Figure out how to VCR YoutubeIt or tell it to fuck off."
    it "returns a nested hash of a video's attributes" do
      video_hash = subject.fetch :youtube, 'cRBcP6MmE8'
      [ :title, :description, :duration, :viewable_mobile, :view_count,
        :published_at, :author_username ].each do |key|
        video_hash.should have_key key
      end
      video_hash[:author].should have_key :username
    end
  end
end
