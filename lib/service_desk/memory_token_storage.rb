class ServiceDesk::MemoryTokenStorage
  attr_reader :access_token, :refresh_token, :expires_at

  def update!(access_token: nil, refresh_token: nil, expires_at: nil)
    @access_token = access_token
    @refresh_token = refresh_token
    @expires_at = expires_at
  end

  def lock
    yield
  end
end

