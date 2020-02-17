# Common code for input handlers.
#
# Example echo server input handler.
#
#   class EchoInputHandler
#     include Morrow::TelnetServer::InputHandler
#     def input_line(line)
#       send_line("recv: #{line}")
#     end
#   end
module Morrow::TelnetServer::InputHandler
  include Morrow::Logging

  attr_reader :conn

  def initialize(conn)
    @conn = conn
  end

  def send_data(buf)
    @conn.send_data(buf)
    nil
  end

  def send_line(line)
    send_data(line + "\n")
    nil
  end

  # check to see if this is the active handler
  def active?
    @conn.handler == self
  end

  # called to notify this handler that it will now receive input
  def resume
  end
end
