module Aji
  class API
    version '1'
    
    resource :users do
      
      get '/:user_id' do
        user = User.find(params[:user_id]) or
          not_found_error!(User, params)
      end
      
      post '/' do
        User.create(params) or creation_error!(User, params) 
      end
      
    end
  end
end
