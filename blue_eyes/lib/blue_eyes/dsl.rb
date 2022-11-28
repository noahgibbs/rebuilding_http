# lib/blue_eyes/dsl.rb
RUBY_MAIN = self

require_relative "../blue_eyes"

# Include the DSL into Ruby main
include BlueEyes::DSL

at_exit do
  s = BlueEyes::Server.new(4321)
  s.start
end
