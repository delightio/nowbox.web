require File.expand_path("../../../spec_helper", __FILE__)

module Aji
  describe Account::Facebook do
    subject { Account::Facebook.create uid: "501776555" }
    it_behaves_like "any account"
  end
end


