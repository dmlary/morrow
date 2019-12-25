module System::Connections
  extend System::Base

  IDLE_TIMEOUT = 5 * 60           # XXX not implemented
  DISCONNECT_TIMEOUT = 30 * 60

  def self.update(entity, conn_comp)
    conn = conn_comp.conn or return

    if conn.error?
      # disconnected
      info("client disconnected; #{conn.inspect}")
      conn.close_connection
      conn_comp.conn = nil
    elsif Time.now > conn.last_recv + DISCONNECT_TIMEOUT
      # timed out
      info("client timed out; #{conn.inspect}")
      conn.send_data("Timed out; closing connection\n")
      conn.close_connection_after_writing
      conn_comp.conn = nil
    elsif buf = conn_comp.buf and !buf.empty?
      conn.send_data(buf)
      buf.clear
    end
  end

  World.register_system(:connections,
      all: [ ConnectionComponent ], method: method(:update))
end

