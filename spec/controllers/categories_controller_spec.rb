require File.expand_path("../../spec_helper", __FILE__)

module Aji
  resource = "categories"
  resource_uri = "/#{API.version.first}/#{resource}"

  describe API do
    describe "resource: #{resource}" do
      subject { Aji::Category.find_or_create_by_raw_title random_string}
      
      describe "get #{resource_uri}/:id" do
        it "returns given category resource" do # TODO
          get "#{resource_uri}/#{subject.id}"
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

        it "returns all featured categories when ?type=featured&user_id=UID are given" do
          params = { :user_id => (Factory :user).id, :type => "featured" }
          get "#{resource_uri}", params
          last_response.status.should == 200
          body_hash = JSON.parse last_response.body
          returned_categories = body_hash.map {|h| h["category"]}
          returned_categories.should have_at_most(10).categories
        end

        it "does not return undefined category" do
          params = { :user_id => (Factory :user).id, :type => "featured" }
          get "#{resource_uri}", params
          last_response.status.should == 200
          body_hash = JSON.parse last_response.body
          returned_categories = body_hash.map {|h| h["category"]}
          returned_categories.should_not include Category.undefined
        end

        it "returns featured categories" do
          Category.should_receive(:featured).and_return([subject])
          params = { :user_id => (Factory :user).id, :type => "featured" }
          get "#{resource_uri}", params
        end
      end
      
      describe "get #{resource_uri}/:id/channels" do
        it "fails if missing user_id" do
          get "#{resource_uri}/#{rand(10)}/channels"
          last_response.status.should == 404
        end
        
        it "returns all featured channels when ?type=featured&user_id=UID are given" do
          params = { :user_id => (Factory :user).id, :type => "featured" }
          subject.should_receive(:featured_channels).and_return([])
          Category.stub(:find_by_id).with(subject.id.to_s).and_return(subject)
          get "#{resource_uri}/#{subject.id}/channels", params
          last_response.status.should == 200
        end
      end
    end
  end
end