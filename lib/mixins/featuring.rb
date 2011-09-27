module Aji
  module Mixins
    module Featuring

      def self.included klass
        klass.extend ClassMethods
        klass.send :include, InstanceMethods
      end

      module ClassMethods
        def featured_key
          klass = self.to_s.split("::").first(2).join("::") # TODO LH 364
          "#{klass}::featured::ids"
        end

        def featured_ids
          redis.lrange(featured_key, 0, -1).map(&:to_i)
        end

        def featured
          find_all_by_id featured_ids
        end

        def set_featured to_be_featured_by_title
          puts "Original featured: #{featured_ids}"
          to_be_featured_by_title.each do |to_be_featured|
            obj = self.find_by_title to_be_featured
            if obj.nil?
              puts "*** Couldn't find: #{to_be_featured}"
              next
            end
            puts "#{to_be_featured} => #{self}[#{obj.id}]"
            obj.feature
          end
          puts "Updated featured: #{featured_ids}"
        end

      end

      module InstanceMethods
        def featured?
          self.class.featured_ids.include? self.id
        end

        def feature
          unless featured?
            redis.rpush self.class.featured_key, self.id
          end
        end

        def unfeature
          redis.lrem self.class.featured_key, 0, self.id
        end
      end

    end
  end
end

