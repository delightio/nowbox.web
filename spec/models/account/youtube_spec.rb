require File.expand_path("../../../spec_helper", __FILE__)
module Aji
  describe Account::Youtube do
    subject { Account::Youtube.create :uid => "nowmov" }
    it_behaves_like "any account"
    it_behaves_like "any content holder"
  end
end
