module Shipcloud
  class ShipcloudError < StandardError
    attr_reader :errors, :response

    def initialize(response = nil)
      @response = response
      @errors = parse_errors
      error_message = errors.empty? ? response_body : errors
      super(error_message)
    end

    # Returns the appropriate Shipcloud::ShipcloudError subclass based
    # on status code
    #
    # @param [HTTPResponse] response HTTP response
    # @return [Shipcloud::ShipcloudError]
    def self.from_response(response)
      response_code = response.code.to_i
      if error_class = error_class_for(response_code)
        error_class.new(response)
      end
    end

    private

    def self.error_class_for(response_code)
      case response_code
      when 400 then InvalidRequestError
      when 401 then AuthenticationError
      when 402 then TooManyRequests
      when 404 then NotFoundError
      when 400..499 then ClientError
      when 500..599 then ServerError
      end
    end

    def parse_errors
      return [] unless response_body
      data = JSON.parse(response_body)
      if data.is_a?(Hash) && data["errors"]
        data["errors"]
      else
        []
      end
    rescue JSON::ParserError
      []
    end

    def response_body
      return unless @response
      @response.body
    end
  end

  # Raised on errors in the 400-499 range
  class ClientError < ShipcloudError; end
  class AuthenticationError < ClientError; end
  class InvalidRequestError < ClientError; end
  class TooManyRequests < ClientError; end
  class NotFoundError < ClientError; end

  # Raised on errors in the 500-599 range
  class ServerError < ShipcloudError; end
end
