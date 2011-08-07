require File.expand_path("../../spec_helper", __FILE__)

describe Aji::Macker do
  describe ".fetch" do

    context "when the network fails" do
      it "throws an error symbol" do
        expect { subject.fetch :youtube, 'cRBcP6MmE8' }.to
        throw_symbol :network_failure
      end
    end

    it "returns a nested hash of a video's attributes" do
      video_hash = subject.fetch :youtube, 'EzT5iKpxjFA'
      [ :title, :description, :duration, :viewable_mobile, :view_count,
        :published_at, :author_username ].each do |key|
        video_hash.should have_key key
      end
      video_hash[:author].should have_key :username
    end
  end
end
