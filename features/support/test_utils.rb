module TestUtils

  def self.included base
    base.send :include, InstanceMethods
    base.send :extend, ClassMethods
  end

  module ClassMethods
    def use_api_subdomain!
      def subdomain
        :api
      end
    end
  end

  module InstanceMethods
    def app
      Aji::APP
    end

    def subdomain
      nil
    end

    def host
      if subdomain
        "#{subdomain}.#{Aji.conf['TLD']}"
      else
        Aji.conf['TLD']
      end
    end

    def build_rack_mock_session
      Rack::MockSession.new app, host
    end

    def json_body response
      MultiJson.decode response.body
    end

    def dump_response_on_failure
      yield
    rescue
      puts last_response.inspect
      raise
    end
  end
end

