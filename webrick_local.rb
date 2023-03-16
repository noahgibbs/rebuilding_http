# webrick_local.rb
require 'webrick'

root = File.expand_path(".")
server = WEBrick::HTTPServer.new Port: 4322,
  DocumentRoot: root
trap('INT') { server.shutdown }
server.start
