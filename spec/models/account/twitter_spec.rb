require File.expand_path("../../../spec_helper", __FILE__)

describe Aji::Account::Twitter do
  it "has a handle" do
    pending "This will be invalidated by making handle a db column"
    steven = Aji::Account::Twitter.new :uid => "178492493",
      :user_info => { :nickname => '_nuclearsammich' }
    steven.handle.should == '_nuclearsammich'
  end

  describe "ALL THE OTHER METHODS"
end
