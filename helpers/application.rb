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

      def invalid_params_error! param_name, param, message
        error! "#{param.inspect} is an invalid value for #{param_name} " +
          message, 400
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

      def force_ssl!
        unless request.scheme == 'https'
          error! '{"error":"Client must use HTTPS to generate tokens."}', 403
        end
      end

      def parse_param p
        case
        when p == 'false' then false
        when p == 'true' then true
        when p.to_i.to_s == p then p.to_i
        when p.to_f.to_s == p then p.to_f
        else p
        end

      rescue
        p
      end
    end
  end
end
