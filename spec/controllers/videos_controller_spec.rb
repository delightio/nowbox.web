require File.expand_path("../../spec_helper", __FILE__)

module Aji
  resource = "videos"
  resource_uri = "/#{API.version.first}/#{resource}"

  describe API do
    describe "resource: #{resource}" do
      describe "get #{resource_uri}/:id" do
        it "should return 404 if not found" do
          get "#{resource_uri}/#{rand(100)}"
          last_response.status.should == 404
        end
        
        it "should return video info if found" do
          video = Factory :video
          get "#{resource_uri}/#{video.id}"
          last_response.status.should == 200
          body_hash = JSON.parse last_response.body
          body_hash.should == video.serializable_hash
        end
      end
    end
  end
end