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
          find featured_ids unless featured_ids.empty?
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

