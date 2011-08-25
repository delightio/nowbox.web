require File.expand_path("../../../spec_helper", __FILE__)
module Aji
  describe Account::Youtube do
    describe "#refresh_content" do
      subject { Account::Youtube.find_or_create_by_uid "nowmov" }

      it_behaves_like "any content holder"
      it "refreshes only unpopulated accounts"
    end

    describe "#thumbnail_uri" do
      it "returns a uri from Youtube API"
      it "replaces default blue ghost with first video" do
        pending "Check for default pic url and replace with our own or vid thumb"
      end
    end
  end
end
