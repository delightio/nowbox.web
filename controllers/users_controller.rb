module Aji
  class API
    version '1'
    
    resource :users do
      
      get '/:user_id' do
        find_user_by_id_or_error params[:user_id]
      end
      
      post '/' do
        User.create(params) or creation_error!(User, params) 
      end
      
    end
  end
end
