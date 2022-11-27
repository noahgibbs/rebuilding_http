# lib/blue_eyes/dsl.rb
RUBY_MAIN = self

require_relative "../blue_eyes"

# Include the DSL into Ruby main
include BlueEyes::DSL

at_exit do
  server = TCPServer.new 4321
  loop do
    client = server.accept
    req = BlueEyes::Request.new(client)
    resp = RUBY_MAIN.match(req)
    client.write resp.to_s
    client.close
  rescue
    puts "Read error! #{$!.inspect}"
    next
  end
end

