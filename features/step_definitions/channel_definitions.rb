Given /^I am logged in as a nowbox user$/ do
  set_current_user Factory :user
end

When /^I ask for a channel containing #{twitter_handle}'s videos$/ do |handle|
  get "/1/channels?type=twitter&account=#{handle}&user_id=#{current_user[:id]}"
end

Then /^I should get a channel for videos shared by #{twitter_handle}$/ do
  |handle|
  resp_body = MultiJson.decode last_response.body
  resp_body.should have_key 'id'
end

Then /^the title should be "([^"]*)"$/ do |channel_title|
  resp_body = MultiJson.decode last_response.body
  resp_body['title'].should == channel_title
end


Given /^a Twitter channel associated with #{twitter_handle}'s twitter account$/ do
  |handle|
  pending # This scenario relies on outside library calls. Will mock with VCR.
  account = Factory :twitter_account, :username => handle
  Factory :twitter_channel, :account => account
end

Given /^@nowbox has tweeted videos recently$/ do
  pending # somehow mock recently tweeted videos
end

When /^I get the channels videos$/ do
  pending # express the regexp above with the code you wish you had
end

Then /^I should see a list of recently tweeted videos$/ do
  pending # express the regexp above with the code you wish you had
end
