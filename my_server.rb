# my_server.rb
require 'socket'

RESP = <<TEXT
HTTP/1.1 200 OK
Content-Type: text/plain

Hello Again World!
TEXT

server = TCPServer.new 4321
loop do
  client = server.accept
  loop do
    line = client.gets
    puts line
    break if line.strip == ""
  end
  client.write RESP
  client.close
end
