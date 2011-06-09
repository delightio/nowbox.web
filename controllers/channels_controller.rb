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
        error!("Unknown action: #{params[:action]}", 400) if !Channel.supported_actions.include? params[:action]
        channel.send params[:action], params[:action_params]
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
