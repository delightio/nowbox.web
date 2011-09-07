require_relative '../aji'

module Aji
  class Category
    # changed the order and which categories to show up when GET /categories
    def self.set_featured_categories to_be_featured_list
      puts "Original featured: " +
        (Aji.redis.lrange featured_key, 0, -1).to_s
      to_be_featured_list.each do |to_be_featured|
        category = self.find_by_title to_be_featured
        if category.nil?
          puts "*** Couldn't find: #{to_be_featured}"
          next
        end
        puts "#{to_be_featured} => Category[#{category.id}]"
        Aji.redis.rpush Aji::Category.featured_key, category.id
      end
      puts "Updated featured: " +
        (Aji.redis.lrange featured_key, 0, -1).to_s
    end
  end
end