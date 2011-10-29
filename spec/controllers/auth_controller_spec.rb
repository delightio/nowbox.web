require File.expand_path("../../spec_helper", __FILE__)

describe "GET /auth/twitter/callback" do
  let!(:user) { Factory :user, :id => 1}
  before do
    def app
      Aji::AuthController
    end
  end

  xit "returns a 404 when the user is not specified" do
    get "twitter/callback"

    last_response.status.should == 404
    last_response.body.should =~ /not found/i
  end

  it "takes a user id parameter" do
    u = Factory :user
    get "twitter/callback?user_id=#{u.id}"

    last_response.status.should_not == 404
    last_response.body.should_not =~ /not found/i
  end
end
