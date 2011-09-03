require File.expand_path("../../spec_helper", __FILE__)

module Aji
  describe Queues::RemoveSpammer do
    subject { Queues::RemoveSpammer }
    describe ".perform" do
      it "marks an account as a spammer" do
        account = mock("account", :id => 1)
        account.should_receive :mark_spammer
        Account.stub(:find).with(account.id).and_return(account)
        subject.perform account.id
      end
    end
  end
end
