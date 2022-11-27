#!/usr/bin/env ruby

require "tempfile"
require "timeout"

SERVER_PID = fork do
  # Timeout is terrible for this, except that luckily we just want
  # it to die afterward, which is all Timeout is safe-ish for.
  Timeout::timeout(5) do
    STDOUT.reopen("/dev/null", "w")
    STDERR.reopen("/dev/null", "w")

    # Replace this process with little_app
    Dir.chdir File.join(__dir__, "..", "blue_eyes")  # Make sure current directory is what we expect
    exec "ruby -I./lib -rblue_eyes/dsl little_app.rb"
  end
  exit(0)
end

# Attempt to clean up server process
at_exit do
  Process.kill 9, SERVER_PID
end

# Let the server start up
sleep 0.5

def assert(condition, msg = nil)
  unless condition
    msg ||= "condition was false!"
    raise "Assertion failed: #{msg}!"
  end
end

def constrain_output(type:, cmd:, file:, constraints:)
  output = File.exist?(file) ? File.read(file) : ""

  if constraints.is_a?(String)
    required = [constraints]
  elsif constraints.is_a?(Array)
    required = constraints
  end

  required.each do |req|
    assert output.include?(req), "#{type.inspect} of #{cmd.inspect} didn't include #{req.inspect}"
  end
end

def check_curl_output cmd: "curl -v http://localhost:4321",
      constraints:, verbose: false
  outfile = Tempfile.new("rebuilding_http_test_out")
  errfile = Tempfile.new("rebuilding_http_test_err")

  pid = spawn cmd, out: [outfile.path, "w"], err: [errfile.path, "w"]
  Process.wait pid

  if $?.success?
    # Ran without error, no problem
    if verbose
      puts "Out: #{File.read outfile.path}"
      puts "Err: #{File.read errfile.path}"
    end
  else
    # Error out
    puts "Error output:"
    puts File.exist?(errfile.path) ? File.read(errfile.path) : "(No file created)"
    raise "Command #{cmd.inspect} failed!"
  end

  if constraints[:out]
    constrain_output(type: "Output", constraints: constraints[:out], file: outfile.path, cmd: cmd)
  end

  if constraints[:err]
    constrain_output(type: "Error", constraints: constraints[:err], file: errfile.path, cmd: cmd)
  end
ensure
  outfile.unlink
  errfile.unlink
end

check_curl_output cmd: "curl http://localhost:4321", constraints: { out: "Who are you looking for?" }
check_curl_output cmd: "curl http://localhost:4321/frank", constraints: { out: "I did it my way..." }

puts "Passed all tests!"

