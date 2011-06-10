require File.expand_path("../../spec_helper", __FILE__)

module Aji
  resource = "channels"
  resource_uri = "/#{API.version.first}/#{resource}"

  describe API do
    describe "resource: #{resource}" do
      
      describe "#{resource_uri}/:channel_id" do
      
        it "should return 404 if not found" do
          puts "#{resource_uri}/#{rand(100)}"
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
        
        it "should only respond to known commands" do
          channel = Factory :trending_channel
          user = Factory :user
          params = {:user_id => user.id, :channel_action => random_string}
          put "#{resource_uri}/#{channel.id}", params
          last_response.status.should == 400
        end
        
        it "should allow subscribing" do
          channel = Factory :trending_channel
          user = Factory :user
          params = {:user_id => user.id, :channel_action => :subscribe}
          put "#{resource_uri}/#{channel.id}", params
          last_response.status.should == 200
        end
        
        it "should allow unsubscribing" do
          channel = Factory :trending_channel
          user = Factory :user
          user.subscribe channel
          params = {:user_id => user.id, :channel_action => :unsubscribe}
          put "#{resource_uri}/#{channel.id}", params
          last_response.status.should == 200
          user.subscribed_channels.should_not include channel
        end
        
        it "should allow channel arrangment" do
          user = Factory :user
          channels = []
          5.times do |n|
            channels << Factory(:channel)
            user.subscribe channels.last
          end
          old_position = 3
          new_position = 1
          channel = channels[old_position]
          params = {:user_id => user.id, :channel_action => :arrange, :channel_action_params=>{:new_position=>new_position}}
          put "#{resource_uri}/#{channel.id}", params
          last_response.status.should == 200
          user.subscribed_channels[new_position] = channel
        end
        
      end
    end
  end
end