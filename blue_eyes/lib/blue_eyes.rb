# frozen_string_literal: true
require 'socket'
require_relative "blue_eyes/version"

module BlueEyes
  class Error < StandardError; end
  class ParseError < Error; end
end

class BlueEyes::Request
  attr_reader :url

  def initialize(s)
    parse_req s.gets

    head = String.new
    loop do
      line = s.gets
      head << line.chomp("\r").chomp("\n") << "\n"
      break if line.strip == ""
    end

    parse_headers(head)
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
  def get(route, &handler)
    @routes ||= []
    @routes << [route, handler]
  end

  def match(url)
    _, h = @routes.detect { |route, _| url[route] }
    if h
      BlueEyes::Response.new(h.call)
    else
      BlueEyes::Response.new("",
        status: 404,
        message: "No route found")
    end
  end
end
