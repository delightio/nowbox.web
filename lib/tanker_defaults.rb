module Aji

  # Please note that you would need to create the index ahead of time
  def Aji.tanker_index_suffix
    if RACK_ENV == "production" then "production" else "sandbox" end
  end

  module TankerDefaults

    module Account
      def self.index; "accounts_#{Aji.tanker_index_suffix}"; end
      def self.included(base)
        base.send(:include, ::Tanker)
        base.tankit index, :as => 'Aji::Account' do
          indexes :username
          indexes :realname
          indexes :description
        end
      end

      def update_tank_indexes_if_searchable
        update_tank_indexes if Searcher.enabled?
      end

      def delete_tank_indexes_if_searchable
        delete_tank_indexes if Searcher.enabled?
      end
    end

    module Channel
      def self.index; "channels_#{Aji.tanker_index_suffix}"; end
      def self.included(base)
        base.send(:include, ::Tanker)
        base.tankit index, :as => 'Aji::Channel' do
          indexes :title
          indexes :description
        end
      end

      def update_tank_indexes_if_searchable
puts "*** Channel#update_tank_indexes_if_searchable called for #{self.id}"
        update_tank_indexes if Searcher.enabled?
      end

      def delete_tank_indexes_if_searchable
        delete_tank_indexes if Searcher.enabled?
      end
    end

  end
end