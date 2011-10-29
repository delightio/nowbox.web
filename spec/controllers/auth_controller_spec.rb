require File.expand_path("../../spec_helper", __FILE__)

describe "GET /auth/twitter/callback" do
  before do
    def app
      Aji::AuthController
    end
  end

  it "returns a 404 when the user is not specified" do
    get "/auth/twitter/callback"

    last_response.status.should == 404
    last_response.body.should =~ /not found/i
  end
  end