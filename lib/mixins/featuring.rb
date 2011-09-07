module Aji
  module Mixins
    module Featuring

      def self.featured_key
        "#{self}::featured::ids"
      end

      def self.featured_ids
        redis.lrange featured_key, 0, -1
      end

      def featured?
        self.class.featured_ids.include? self.id
      end

      def feature
        unless featured?
          redis.rpush self.class.featured_key, self.id
        end
      end

      def self.featured
        find featured_ids unless featured_ids.empty?
      end

    end
  end
end

