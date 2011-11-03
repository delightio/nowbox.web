# Categories Controller
# =================
# Category object json:
#
# {`id`:1,
#  `title`:"News"}
module Aji
  class API
    version '1'
    resource :categories do

      # ## GET categories/
      # __Returns__ all the featured categories for given user. Code 200 or 404
      #
      # __Required params__ `type` type of categories to be returned
      #
      # __Optional params__ `user_id` unique id of the current user

      get do
        error!("Missing/Invalid parameter: type != featured", 404) if params[:type]!="featured"
        categories = Category.featured
        categories
      end

      # ## GET categories/:category_id/channels
      # __Returns__ the channels associated with the specified category id. Code 200 or 404
      #
      # __Required params__ `category_id` unique id of the category
      #
      # __Required params__ `user_id` unique id of the current user
      #
      # __Optional params__ none
      get '/:category_id/channels' do
        error!("Missing parameter: category_id", 404) if params[:category_id].nil?
        error!("Missing/Invalid parameter: type != featured", 404) if params[:type]!="featured"
        error!("Missing parameter: user_id", 404) if params[:user_id].nil?
        c = Category.find_by_id params[:category_id]
        c.featured_channels if c
      end

      # ## GET categories/:category_id
      # __Returns__ given cateogry object. Code 200 or 404
      #
      # __Required params__ `category_id` unique id of the category
      #
      # __Optional params__ none
      get '/:category_id' do
        error!("Missing parameter: category_id", 404) if params[:category_id].nil?
        Category.find_by_id params[:category_id]
      end
    end
  end
end
