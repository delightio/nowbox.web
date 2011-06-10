module Aji
  class API
    version '1'

    resource :channels do
      
      get '/:channel_id' do
        find_channel_by_id_or_error params[:channel_id]
      end
      
      post do
        channel = Channel.create(params) or creation_error!(params)
      end
      
      put '/:channel_id' do
        channel = find_channel_by_id_or_error params[:channel_id]
        error!("Unknown channel action: #{params[:channel_action]}", 400) if !User.supported_channel_actions.include? params[:channel_action].to_sym
        user = find_user_by_id_or_error params[:user_id]
        succeeded = user.send params[:channel_action], channel, params[:channel_action_params]
        error!("User[#{user.id}] cannot #{params[:channel_action]} Channel[#{channel.id}] with params: #{params[:channel_action_params].inspect}", 400) if !succeeded
        "ok"
      end
      
      get '/:channel_id/videos' do
        channel = find_channel_by_id_or_error params[:channel_id]
        user = find_user_by_id_or_error params[:user_id]
        user.personalized_videos :channel => channel, :params => params
      end
      
      helpers do
      end
    end
  end
end
