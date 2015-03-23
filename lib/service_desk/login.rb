require 'securerandom'
require 'webrick'

class ServiceDesk::Login
  Error = Class.new(StandardError)
  InvalidStateError = Class.new(Error)
  InvalidResponse = Class.new(Error)

  def initialize(client)
    @client = client
  end

  def call
    @state = SecureRandom.hex
    url = @client.authorize_url(@state)

    puts "*" * 120
    puts "Now opening your web browser for you to authenticate with Service Desk."
    puts "We're also going to start a server at #{@client.config.redirect_uri} to capture the response from Service Desk.  Make sure you don't have anything else running on that port."
    puts "*" * 120
    puts

    open_url_in_local_browser(url)
    start_web_server_then_request_token
  end

  private

  def open_url_in_local_browser(url)
    case RUBY_PLATFORM
    when /darwin/
      system "open", url
    else
      puts "Please copy and paste the following URL into your web browser:\n  #{url}"
    end
  end

  def start_web_server_then_request_token
    uri = URI.parse(@client.config.redirect_uri)

    server = WEBrick::HTTPServer.new :Port => uri.port
    server.mount_proc uri.path do |request, response|
      if request.query["code"].nil?
        fail InvalidResponse, "No oauth2 code was returned; something bad happened?"
      end

      if request.query["state"] != @state
        fail InvalidStateError, "The state passed back does not match the one we sent; someone might be attempting an attack"
      end

      @token = @client.token_from_code(request.query["code"], @state)

      response.body = "All done!  Head back to your terminal to continue."
      server.shutdown
    end

    server.start
    @token
  end
end
