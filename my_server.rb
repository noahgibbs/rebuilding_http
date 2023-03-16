# my_server.rb
require 'socket'

RESP = <<TEXT
HTTP/1.1 200 OK
Content-Type: text/plain

Hello World!
TEXT

server = TCPServer.new 4321
loop do
  client = server.accept
  puts "Got a connection!"
  puts client.gets.inspect
  client.write RESP
  client.close
end

