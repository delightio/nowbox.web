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

      def searchable?
        Searcher.enabled? &&
        content_video_id_count >= Searcher.minimun_video_count
      end

      def update_tank_indexes_if_searchable
        if searchable?
          Aji.log "Account[#{id}].update_tank_indexes"
          update_tank_indexes
        end
        # update_tank_indexes if searchable?
      end

      def delete_tank_indexes_if_searchable
        delete_tank_indexes if searchable?
      end
    end

  end
end