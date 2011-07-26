require File.expand_path("../../../spec_helper", __FILE__)

describe Aji::ExternalAccounts::Twitter do
  it "has a handle" do
    steven = Aji::ExternalAccounts::Twitter.new :uid => "178492493",
      :user_info => { :nickname => '_nuclearsammich' }
    steven.handle.should == '_nuclearsammich'
  end
end
