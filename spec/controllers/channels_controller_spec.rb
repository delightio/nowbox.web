require File.expand_path("../../spec_helper", __FILE__)

resource = "channels"
resource_uri = "/#{Aji::API.version.first}/#{resource}"

describe Aji::API do
  describe "resource: #{resource}" do

    describe "#{resource_uri}/:channel_id" do
      
      it "should return 404 if not found" do
        get "#{resource_uri}/#{rand(100)}"
        last_response.status.should == 404
      end
      
      it "should channel info if found" do
        channel = Factory :trending_channel
        get "#{resource_uri}/#{channel.id}"
        last_response.status.should == 200
        body_hash = JSON.parse last_response.body
        body_hash.should == channel.serializable_hash
      end
      
    end

  end
end
