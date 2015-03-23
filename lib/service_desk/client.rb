require 'cgi'
require 'net/http'
require 'json'

class ServiceDesk::Client
  def self.configure
    yield config
  end

  def self.config
    @configuration ||= ServiceDesk::Configuration.new
  end

  attr_reader :config

  def initialize(config: nil)
    @config = config || self.class.config
  end

  def token_from_code(code, state)
    hash = authentication_request(grant_type: "authorization_code", code: code, redirect_uri: config.redirect_uri, state: state)
    ServiceDesk::Token.new(self).load_from_hash(hash)
  end

  def token_from_refresh_token
    ServiceDesk::Token.new(self).renew_if_expired!
  end

  def authorize_url(state)
    "#{config.api_host}#{config.authenticate_path}?client_id=#{CGI.escape config.client_id}&redirect_uri=#{CGI.escape config.redirect_uri}&response_type=code&state=#{CGI.escape state}"
  end

  def authentication_request(data)
    do_request config.authenticate_path, Net::HTTP::Post do |request|
      request.basic_auth(config.client_id, config.client_secret)
      request.set_form_data(data)
    end
  end

  def do_request(url, request_class, headers = {})
    uri = URI.parse("#{config.api_host}#{url}")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = uri.scheme == 'https'

    request = request_class.new(uri.request_uri, headers)
    yield request if block_given?
    response = http.request(request)

    if response.code =~ /\A2\d\d\z/
      JSON.parse(response.body)
    else
      handle_non_200_response(response)
    end
  end

  private

  def handle_non_200_response(response)
    if response.content_type == 'application/json'
      api_data = JSON.parse(response.body) rescue {}

      if api_data["error"]
        error = ServiceDesk::ERROR_CODE_CLASS_MAPPING.fetch(api_data["code"], ServiceDesk::Error)
        raise error, "Service Desk returned #{response.code} and raised error #{api_data["code"]}: #{api_data["error"]}"
      end
    end

    raise ServiceDesk::HTTPError.new("API returned HTTP error code #{response.code}: #{response.body}", response.body)
  end
end
