require 'sinatra'

get '/' do
  'Here I am!'
end

run Sinatra::Application

