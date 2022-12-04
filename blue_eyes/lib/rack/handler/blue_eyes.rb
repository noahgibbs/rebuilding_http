require "rack"
require_relative "../../blue_eyes"

class Rack::Handler::BlueEyes
  def self.run(app, config)
    port = config[:Port]
    puts "Starting BlueEyes on port #{port}"
    server = BlueEyes::Server.new(port, app)
    server.start
  end
end

Rack::Handler.register :blue_eyes,
  ::Rack::Handler::BlueEyes
