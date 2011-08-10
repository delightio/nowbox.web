require File.expand_path("../../spec_helper", __FILE__)

describe Aji::Macker do
  describe ".fetch" do

    context "given a bad external id" do
      it "raises an exception" do
        expect { subject.fetch :youtube, 'cRBcP6MmE8' }.to
        raise_exception Aji::Macker::FetchError
      end
    end

    it "returns a nested hash of a video's attributes" do
      video_hash = subject.fetch :youtube, 'EzT5iKpxjFA'
      [ :title, :description, :duration, :viewable_mobile, :view_count,
        :published_at, :author_id, :category_id ].each do |key|
        video_hash.should have_key key
      end
    end
  end
end
