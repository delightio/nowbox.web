# Categories Controller
# =================
# Category object json:
#
# {`id`:1,
#  `title`:"News",
#  `chanel_ids`:["1","2","3","4","5","6"]}
module Aji
  class API
    version '1'
    resource :categories do

      # ## GET categories/
      # __Returns__ all the featured categories for given user. Code 200 or 404
      #
      # __Required params__ `user_id` unique id of the current user  
      # __Required params__ `type` type of categories to be returned
      get do
        error!("Missing/Invalid parameter: type != featured", 404) if params[:type]!="featured"
        error!("Missing parameter: user_id", 404) if params[:user_id].nil?
        categories = Category.all.sample(10)
        if categories.count < 10
          (10-categories.count).times do |n|
            categories << (Category.create :title => ::String.random)
          end
        end
        categories
      end

      # ## GET categories/:category_id/channels
      # __Returns__ the channels associated with the specified category id. Code 200 or 404
      #
      # __Required params__ `category_id` unique id of the category  
      # __Required params__ `user_id` unique id of the current user  
      # __Optional params__ none
      get '/:category_id/channels' do
        error!("Missing parameter: category_id", 404) if params[:category_id].nil?
        error!("Missing/Invalid parameter: type != featured", 404) if params[:type]!="featured"
        error!("Missing parameter: user_id", 404) if params[:user_id].nil?
        Channel.all.sample(1+rand(10))
      end

      # ## GET categories/:category_id
      # __Returns__ given cateogry object. Code 200 or 404
      #
      # __Required params__ `category_id` unique id of the category  
      # __Optional params__ none
      get '/:category_id' do
        error!("Missing parameter: category_id", 404) if params[:category_id].nil?
        Category.new
      end
    end
  end
end
