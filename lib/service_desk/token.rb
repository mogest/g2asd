require 'forwardable'

class ServiceDesk::Token
  extend Forwardable
  
  EXPIRY_FORWARD_SECONDS = 15

  def_delegators :token_storage, :access_token, :expires_at

  def initialize(client)
    @client = client
  end

  def load_from_hash(hash)
    raise "No access token specified" unless hash["access_token"]

    self.refresh_token = hash["refresh_token"]
    token_storage.update!(access_token: hash["access_token"], refresh_token: hash["refresh_token"], expires_at: Time.now + hash["expires_in"])
    self
  end

  def get(url)
    renew_if_expired!
    retry_on_access_token_error do
      handle_errors @client.do_request(url, Net::HTTP::Get, "Authorization" => "Bearer #{access_token}", "Accept" => "application/json")
    end
  end

  def renew!
    token_storage.lock do
      load_from_hash @client.authentication_request(grant_type: "refresh_token", refresh_token: refresh_token)
    end
  end

  def expired?
    expires_at.nil? || expires_at < Time.now + EXPIRY_FORWARD_SECONDS
  end

  def renew_if_expired!
    token_storage.lock do
      renew! if expired?
      self
    end
  end

  def refresh_token
    @client.config.refresh_token
  end

  def refresh_token=(value)
    @client.config.refresh_token value
  end

  private

  def token_storage
    @client.config.token_storage
  end

  def handle_errors(api_data)
    if api_data["error"]
      error = ServiceDesk::ERROR_CODE_CLASS_MAPPING.fetch(api_data["code"], ServiceDesk::Error)
      raise error, "Service Desk raised error #{api_data["code"]}: #{api_data["error"]}"

    elsif api_data["objects"].nil? && api_data["object"].nil?
      raise ServiceDesk::Error, "Service Desk didn't return valid data: #{api_data.inspect}"
    end

    api_data
  end

  def retry_on_access_token_error
    retried = false

    begin
      yield
    rescue ServiceDesk::InvalidAccessTokenError
      raise if retried
      retried = true
      renew!
      retry
    end
  end
end

