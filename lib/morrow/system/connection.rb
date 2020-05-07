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

      prompt = comp.last_recv > comp.last_send
      buf = comp.buf
      config = get_component(actor, :config)

      if !buf.empty?
        buf.prepend("\n") unless comp.last_recv > comp.last_send
        buf << "\n" unless config && config.compact
        conn.send_data(buf)
        buf.clear
        conn.send_data(player_prompt(actor))
        comp.last_send = now
      elsif prompt
        conn.send_data(player_prompt(actor))
        comp.last_send = now
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
