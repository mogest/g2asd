require 'yaml'

class ServiceDesk::FileTokenStorage
  attr_reader :access_token, :refresh_token, :expires_at

  def initialize(file_path = File.expand_path("~/.g2asd"))
    @file_path = file_path

    if File.readable?(file_path)
      @configuration = YAML.load(IO.read(file_path))

      @access_token = @configuration["access_token"]
      @expires_at = @configuration["expires_at"]
      @refresh_token = @configuration["refresh_token"]
    end
  end

  def update!(access_token: nil, refresh_token: nil, expires_at: nil)
    configuration = {
      "access_token" => access_token,
      "refresh_token" => refresh_token,
      "expires_at" => expires_at
    }

    File.write(@file_path, YAML.dump(configuration.merge(additional_fields)))
  end

  def lock
    yield
  end

  private

  # If you'd like to store additional fields in the YAML file, overload this method.
  def additional_fields
    {}
  end
end
