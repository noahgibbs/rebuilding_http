# my_server.rb
require_relative 'lib/rebuilding_http'
include RHTTP

server = TCPServer.new 4321
loop do
  client = server.accept
  req = RHTTP.get_request(client)
  puts req.inspect
  resp = RHTTP::Response.new("Hello Response!",
    headers: { 'Framework': 'UltraCool 0.1' })
  client.write resp.to_s
  client.close
rescue  # Add these lines at the end
  puts "Read error! #{$!.inspect}"
  next
end
