class ServiceDesk::Configuration
  OPTIONS = [:client_id, :client_secret, :redirect_uri, :api_host, :authenticate_path, :token_storage, :refresh_token]

  def initialize
    api_host          "https://deskapi.gotoassist.com"
    authenticate_path "/v2/authenticate/oauth2"
  end

  OPTIONS.each do |option|
    define_method(option) do |value=nil|
      if value
        instance_variable_set("@#{option}", value)
      else
        instance_variable_get("@#{option}")
      end
    end
  end
end
