# test_server.rb
require_relative 'lib/blue_eyes'

server = TCPServer.new 4321
loop do
  client = server.accept
  req = BlueEyes::Request.new(client)
  resp = BlueEyes::Response.new("Hello from Ruby!")
  client.write resp.to_s
  client.close
rescue
  puts "Read error! #{$!.inspect}
  next
end

