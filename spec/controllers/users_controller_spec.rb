require File.expand_path("../../spec_helper", __FILE__)

module Aji
  resource = "users"
  resource_uri = "/#{API.version.first}/#{resource}"

  describe API do
    describe "resource: #{resource}" do
      let(:bob) { Factory :user, name: "Bob" }
      before do
        tg = Token::Generator.new bob
        header 'X-NB-AuthToken', tg.token
      end

      describe "get #{resource_uri}/:id" do
        it "should return 404 if not found" do
          get "#{resource_uri}/#{rand(100)}"
          last_response.status.should == 404
        end

        it "should return user info if found" do
          channel = Channel.create
          bob.subscribe channel


          get "#{resource_uri}/#{bob.id}"

          last_response.status.should == 200
          body_hash = JSON.parse last_response.body
          body_hash.should == bob.serializable_hash
          body_hash["subscribed_channel_ids"].should ==
            bob.subscribed_channel_ids
          [:queue_channel_id, :favorite_channel_id,
            :history_channel_id].each do |c|
            body_hash[c.to_s].should == (bob.send c)
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
          header 'X-NB-AuthToken', Token::Generator.new(user).token
          params = { name: "Thomas Pun", email: "dapunster@gmail.com" }
          put "#{resource_uri}/#{user.id}", params
          last_response.status.should == 200
          user.reload
          user.name.should == "Thomas Pun"
          user.email.should == "dapunster@gmail.com"
        end

        it "returns error if missing email parameter" do
          put "#{resource_uri}/#{bob.id}"
          last_response.status.should == 400
        end
      end

      describe "settings API" do
        describe "get #{resource_uri}/:id/settings" do
          it "returns a JSON object representing the user's settings" do
            bob.settings = { :post_to_twitter => false,
                             :wadsworth_mode => true }
            bob.save

            get "#{resource_uri}/#{bob.id}/settings"

            last_response.body.
              should == '{"post_to_twitter":false,"wadsworth_mode":true}'
          end
        end

        describe "put #{resource_uri}/:id/settings" do
          it "updates the users settings with the parameters" do
            bob.settings = { :a_param => "old value" }
            bob.save
            put "#{resource_uri}/#{bob.id}/settings", :settings => {
              :a_param => "a value" }

            bob.reload.settings.should == { :a_param => "a value" }
            last_response.body.should == '{"a_param":"a value"}'
          end

          it "doesn't touch unspecified settings" do
            bob.settings = { :existing_param => "set", :other => "oldvalue" }
            bob.save

            put "#{resource_uri}/#{bob.id}/settings", :settings => {
              :other => "newvalue" }

            last_response.body.
              should == '{"existing_param":"set","other":"newvalue"}'
          end

          it "sets boolean parameters to booleans not strings" do
            bob.settings = { :a_param => "old value" }
            put "#{resource_uri}/#{bob.id}/settings", :settings => {
              :a_param => true, :b_param => false }

            bob.reload.settings.should == { :a_param => true,
              :b_param => false }
            last_response.body.should == '{"a_param":true,"b_param":false}'
          end

          it "sets numeric parameters to numerics not strings" do
            bob.settings = { :a_param => "old value" }
            put "#{resource_uri}/#{bob.id}/settings", :settings => {
              :a_param => 66, :b_param => 9.9 }

            bob.reload.settings.should == { :a_param => 66,
              :b_param => 9.9 }
            last_response.body.should == '{"a_param":66,"b_param":9.9}'
          end

          it "responds with a 400 when no settings hash is passed in" do
            put "#{resource_uri}/#{bob.id}/settings", :oops => "forgot to nest"
            last_response.status.should == 400
            last_response.body.should =~ /Missing params,/

            put "#{resource_uri}/#{bob.id}/settings", :settings => [:foo, :bar]
            last_response.status.should == 400
            last_response.body.should =~ /Settings must be dictionary\/hash/
          end
        end
      end
    end
  end
end

