module Aji
  class API
    version '1'

    resource :users do

      get '/:user_id' do
        user = User.find(params[:user_id]) or
          no_user_error params[:user_id]
      end

      helpers do
        def no_user_error id
          error! "User[#{id}] does not exist", 404
        end
      end
    end
  end
end
