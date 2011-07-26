Given /^I am logged in as a nowmov user$/ do
  set_current_user Factory :user
end

When /^I ask for a channel containing #{twitter_handle}'s videos$/ do |handle|
  get "/1/channels?type=twitter&account=#{handle}&user_id=#{current_user[:id]}"

end

Then /^I should get a channel for videos shared by #{twitter_handle}$/ do |handle|
  resp_body = MultiJson.decode last_response.body
  resp_body.should have_key 'twitter_account'
  resp_body['twitter_account'].should have_key 'id'
end
