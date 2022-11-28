# frozen_string_literal: true
require 'socket'
require_relative "blue_eyes/version"

module BlueEyes
  class Error < StandardError; end
  class ParseError < Error; end
end

class BlueEyes::Request
  attr_reader :url
  attr_reader :method
  attr_reader :body
  attr_reader :form_data
  attr_reader :headers

  URLENCODED = 'application/x-www-form-urlencoded'

  def initialize(s)
    parse_req s.gets

    head = String.new
    loop do
      line = s.gets
      head << line.chomp("\r").chomp("\n") << "\n"
      break if line.strip == ""
    end

    parse_headers(head)

    if @headers['content-type'] == URLENCODED
      len = @headers['content-length']
      if len
        @body = s.read(len.to_i)
      else
        error = BlueEyes::ParseError
        raise error.new("Need length for data!")
      end
      parse_form_body(@body)
    end
  end

  def parse_req(line)
    @method, @url, rest = line.split(/\s/, 3)
    if rest =~ /HTTP\/(\d+)\.(\d+)/
      @http_version = "#{$1}.#{$2}"
    else
      pe = BlueEyes::ParseError
      raise pe.new("Can't parse request")
    end
  end

  def parse_headers(text)
    @headers = {}
    text.lines.each do |line|
      break if line.strip.empty?
      field, value = line.split(":", 2)
      @headers[field.downcase] = value.strip
    end
  end

  def parse_form_body(s)
    data = {}
    s.split(/[;&]/).each do |kv|
      next if kv.empty?
      key, val = kv.split("=", 2)
      data[form_unesc(key)] = form_unesc(val)
    end
    @form_data = data
  end

  def form_unesc(str)
    str = str.gsub("+", " ")
    str.gsub!(/%([0-9a-fA-F]{2})/) {$1.hex.chr}
    str
  end
end

class BlueEyes::Response
  def initialize(body,
      version: "1.1",
      status: 200,
      message: "OK",
      headers: {})
    @version = version
    @status = status
    @message = message
    @headers = headers
    @body = body
  end

  def to_s
    lines = [
      "HTTP/#{@version} #{@status} #{@message}"
    ] + @headers.map { |k,v| "#{k}: #{v}" } +
    [ "", @body, "" ]
    lines.join("\r\n")
  end
end

module BlueEyes::DSL
  def match_route(route, method: :get, &handler)
    @routes ||= []
    case(route)
    when String
      p = proc { |u| u.start_with?(route) }
    when Regexp
      p = proc { |u| u.match?(route) }
    else
      pe = BlueEyes::ParseError
      raise pe.new("Unexpected route!")
    end
    @routes << [p, method, handler]
  end

  def get(route, &h)
    match_route(route, method: :get, &h)
  end

  def post(route, &h)
    match_route(route, method: :post, &h)
  end

  def match(request)
    url = request.url
    method = request.method.downcase.to_sym
    _, _, h = @routes.detect do |p, m, _|
      m == method && p[url]
    end
    if h
      body = request.instance_eval(&h)
      BlueEyes::Response.new(body,
        headers: {'content-type': 'text/html'})
    else
      puts "No match"
      BlueEyes::Response.new("",
        status: 404,
        message: "No route found")
    end
  end
end

class BlueEyes::Server
  NUM_THREADS=10
  MAX_WAITING=20

  def initialize(port)
    @server = TCPServer.new(port)
    @queue = Thread::Queue.new
    @pool = (1..NUM_THREADS).map {
      Thread.new { worker_loop } }
    @resp_full = BlueEyes::Response.new("",
      status: 503, message: "Server too busy!")
  end

  def start
    loop do
      client = @server.accept
      if @queue.num_waiting < MAX_WAITING
        @queue.push(client)
      else
        client.write(@resp_full.to_s)
        client.close
      end
    end
  end

  def worker_loop
    loop do
      client = @queue.pop

      req = BlueEyes::Request.new(client)
      resp = RUBY_MAIN.match(req)
      client.write resp.to_s
      client.close
    rescue
      puts "Read error! #{$!.inspect}"
      next
    end
  end
end
