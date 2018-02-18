module System::Connections
  extend System::Base

  IDLE_TIMEOUT = 5 * 60           # XXX not implemented
  DISCONNECT_TIMEOUT = 30 * 60

  World.register_system(:connection) do |entity, comp|
    conn = comp.get or next

    if conn.error?
      # disconnected
      info("client disconnected; #{conn.inspect}")
      conn.close_connection
      comp.set(nil)
    elsif Time.now > conn.last_recv + DISCONNECT_TIMEOUT
      # timed out
      info("client timed out; #{conn.inspect}")
      send_data("Timed out; closing connection\n", entity: entity)
      conn.close_connection_after_writing
      comp.set(nil)
    end
  end
end

