module ServiceDesk
  Error = Class.new(StandardError)
  InvalidAccessTokenError = Class.new(Error)

  ERROR_CODE_CLASS_MAPPING = {
    "E14" => InvalidAccessTokenError
  }

  class HTTPError < Error
    attr_reader :body

    def initialize(message, body)
      super message
      @body = body
    end
  end
end

require 'service_desk/client'
require 'service_desk/configuration'
require 'service_desk/file_token_storage'
require 'service_desk/login'
require 'service_desk/memory_token_storage'
require 'service_desk/token'
