require File.expand_path("../../spec_helper", __FILE__)

describe "GET /auth/twitter" do
  xit "returns updated user json" do
    get "/auth/twitter?user_id=1"
  end
end
