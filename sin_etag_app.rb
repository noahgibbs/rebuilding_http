# sin_etag_app.rb
require 'sinatra'
require 'digest'

set server: "blueeyes"

get '/etagged' do
  ctr = Time.now.to_i / 30
  text = "Content: #{ctr}"
  tag = Digest::SHA2.hexdigest text
  cache_control :public, max_age: 0
  etag(tag) # note: may return early
  STDERR.puts "Uncached!"
  text
end
