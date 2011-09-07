module Aji
  class API
    helpers do
      def not_found_error! a_class, params
        error! "Cannot find #{a_class} by #{params.inspect}", 404
      end
      def creation_error! a_class, params
        error! "Cannont create #{a_class} with #{params.inspect}", 500
      end

      def missing_params_error! params, required_params
        error! "Missing params, #{required_params.inspect}, from " +
          params.inspect, 400
      end

      def must_supply_params_error! possible_params
        error! "No parameters given. Possible parameters are " +
          possible_params * ', ', 400
      end

      def find_channel_by_id_or_error id
        Aji::Channel.find_by_id(id) or not_found_error!(Channel, id)
      end

      def find_share_by_id_or_error id
        Aji::Share.find_by_id(id) or not_found_error!(Share, id)
      end

      def find_user_by_id_or_error id
        Aji::User.find_by_id(id) or not_found_error!(User, id)
      end
      def find_video_by_id_or_error id
        Aji::Video.find_by_id(id) or not_found_error!(Video, id)
      end
    end
  end
end
