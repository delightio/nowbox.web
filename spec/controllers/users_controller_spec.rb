require File.expand_path("../../spec_helper", __FILE__)

module Aji
  resource = "users"
  resource_uri = "/#{API.version.first}/#{resource}"

  describe API do
    describe "resource: #{resource}" do

      describe "get #{resource_uri}/:id" do
        it "should return 404 if not found" do
          get "#{resource_uri}/#{rand(100)}"
          last_response.status.should == 404
        end

        it "should return user info if found" do
          user = User.create
          channel = Channel.create
          user.subscribe channel

          get "#{resource_uri}/#{user.id}"
          last_response.status.should == 200
          body_hash = JSON.parse last_response.body
          body_hash.should == user.serializable_hash
          body_hash["subscribed_channel_ids"].should == user.subscribed_list.values
          [:queue_channel_id, :favorite_channel_id,
            :history_channel_id].each do |c|
            body_hash[c.to_s].should == (user.send c)
          end
        end
      end

      describe "post #{resource_uri}" do
        it "should create user object on post with default channel listing" do
          post "#{resource_uri}/"
          last_response.status.should ==201
          user_hash = JSON.parse last_response.body
          User.find(user_hash["id"]).should_not be_nil
        end

        it "assigns new user object with underfined region" do
          post "#{resource_uri}/"
          last_response.status.should ==201
          user_hash = JSON.parse last_response.body
          User.find(user_hash["id"]).region.should == Region.undefined
        end

        it "assigns the correct region when specific" do
          params = {:language => "ko", :locale => "ko_KR"}
          region = Region.create params

          post "#{resource_uri}/", params
          last_response.status.should ==201
          user_hash = JSON.parse last_response.body
          User.find(user_hash["id"]).region.should == region
        end
      end

      describe "put #{resource_uri}/:id" do
        it "updates given parameters" do
          user = Aji::User.create
          params = { name: "Thomas Pun", email: "dapunster@gmail.com" }
          put "#{resource_uri}/#{user.id}", params
          last_response.status.should == 200
          user.reload
          user.name.should == "Thomas Pun"
          user.email.should == "dapunster@gmail.com"
        end

        it "returns error if missing email parameter" do
          put "#{resource_uri}/#{Aji::User.create.id}"
          last_response.status.should == 400
        end
      end

    end
  end
end
