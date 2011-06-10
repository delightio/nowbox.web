require File.expand_path("../../spec_helper", __FILE__)

resource = "channels"
resource_uri = "/#{Aji::API.version.first}/#{resource}"

describe Aji::API do
  describe "resource: #{resource}" do
    before(:each) do
      Aji::REDIS.keys.each {|k| Aji::REDIS.del k}
      Aji::Channel.all.each {|c| c.delete}
    end
  
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
      
      Aji::User.supported_channel_actions.each do |channel_action|
        it "should respond to user's #{channel_action} aciton on channel"
      end
      
    end

  end
end
