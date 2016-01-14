module Shipcloud
  module Request
    class Base
      attr_reader :info

      def initialize(info)
        @info = info
      end

      def perform
        raise AuthenticationError if Shipcloud.api_key.nil?
        connection.setup_https
        response = connection.request
        validate_response(response)
        JSON.parse(response.body)
      rescue JSON::ParserError
        raise ShipcloudError.new(response)
      end

      protected

      def validate_response(response)
        error = ShipcloudError.from_response(response)
        if error
          raise error
        end
      end

      def connection
        @connection ||= Connection.new(info)
      end
    end
  end
end
