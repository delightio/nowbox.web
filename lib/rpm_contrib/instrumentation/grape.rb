require 'new_relic/agent/instrumentation/controller_instrumentation'

module RPMContrib
  module Instrumentation
    module Grape
      def self.included grape
        return unless defined?(::Grape) && defined?(::Grape::Endpoint)

        case
        when grape == ::Grape
          NewRelic::Agent.logger.debug "Installing Grape Instrumentation from Grape"
        when grape == ::Grape::Endpoint
          NewRelic::Agent.logger.debug "Installing Grape Instrumentation from Grape::Endpoint"
        else
          NewRelic::Agent.logger.debug "WTF are you doing?" +
            " Installing Grape Instrumentation from #{base.to_s}"
        end
          ::Grape::Endpoint.class_eval do
            include NewRelic::Agent::Instrumentation::ControllerInstrumentation
            include CallWithNewRelic

            alias call_without_newrelic call
            alias call call_with_newrelic
          end
      end


      module CallWithNewRelic
        def call_with_newrelic(env)
          @request = Rack::Request.new(env)
          name = "#{@request.request_method} #{@request.path_info}"
          perform_action_with_newrelic_trace(:category => :sinatra,
            :name => name, :path => request.path, :params => @request.params) do
            call_without_newrelic(env)
          end
        end
      end
    end
  end
end

