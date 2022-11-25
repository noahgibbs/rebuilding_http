# lib/rebuilding_http.rb
require "socket"

HELLO_WORLD_RESPONSE = <<TEXT
HTTP/1.1 200 OK
Content-Type: text/plain

Hello From a Library, World!
TEXT

module RHTTP
  def read_request(sock)
    out = ""
    loop do
      line = sock.gets
      out << line.chomp << "\n"
      return(out) if line.strip == ""
    end
  end
end

