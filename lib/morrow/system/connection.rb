# This system is responsible for managing connections.  It handles timeouts,
# disconnects, and any cleanup required on disconnect.
module Morrow::System::Connection
  extend Morrow::System

  class << self
    def view
      { all: :connection }
    end

    def update(actor, comp)
      conn = comp.conn or return

      if conn.error?
        info "client disconnected; #{conn.inspect}"
        conn.close_connection
        remove_component(actor, comp)
      end

      if buf = comp.buf and !buf.empty?
        conn.send_data(buf)
        buf.clear
        conn.send_data("\n" << player_prompt(actor))
      end

      if now > comp.last_recv + Morrow.config.disconnect_timeout
        info "client timed out; #{conn.inspect}"
        conn.send_data("timed out; closing connection\n")
        conn.close_connection_after_writing
        remove_component(actor, comp)
      end
    end
  end
end
