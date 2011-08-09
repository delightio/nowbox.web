require File.expand_path("../../spec_helper", __FILE__)

module Aji
  resource = "categories"
  resource_uri = "/#{API.version.first}/#{resource}"

  describe API do
    describe "resource: #{resource}" do
      before(:each) do
        20.times { |n| Factory :youtube_channel_with_videos }
      end
      
      describe "get #{resource_uri}/:id" do
        it "never fails with any given category id" do # TODO
          get "#{resource_uri}/#{1+rand(10)}"
          last_response.status.should == 200
        end
      end
      
      describe "get #{resource_uri}/" do
        it "fails if missing type or user_id" do
          get "#{resource_uri}"
          last_response.status.should == 404
          get "#{resource_uri}", :type => random_string
          last_response.status.should == 404
          get "#{resource_uri}", :user_id => rand(10)
          last_response.status.should == 404
        end

        it "returns all featured categories when ?type=featured&user_id=:uid are given" do
          params = { :user_id => (Factory :user).id, :type => "featured" }
          get "#{resource_uri}", params
          last_response.status.should == 200
          body_hash = JSON.parse last_response.body
          returned_categories = body_hash.map {|h| h["category"]}
          returned_categories.should have(10).categories
          returned_categories
        end
        
        it "returns all categories if no parameter is given"
      end
      
      describe "get #{resource_uri}/:id/channels" do
        it "fails if missing user_id" do
          get "#{resource_uri}/#{1+rand(10)}/channels"
          last_response.status.should == 404
        end
        
        it "returns all featured channels when ?type=featured&user_id=:uid are given" do
          params = { :user_id => (Factory :user).id, :type => "featured" }
          get "#{resource_uri}/#{1+rand(10)}/channels", params
          last_response.status.should == 200
          channels = JSON.parse last_response.body
          channels.should be_a_kind_of(::Array)
          channels.count.should > 1
        end
      end
    end
  end
end