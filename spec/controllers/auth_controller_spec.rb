require File.expand_path("../../spec_helper", __FILE__)

describe "GET /auth/twitter" do
  it "returns updated user json" do
    get "/auth/twitter?user_id=1"
    puts last_response.body
  end
end
