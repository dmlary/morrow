class System::Connections < System::Base
  def update(entities)
    timeout = Time.now - 60 * 30

    entities.each do |entity|
      next unless conn = (comp = entity.get(:connection)).value
      if conn.error?
        # disconnected
        info("client disconnected; #{conn.inspect}")
        conn.close_connection
        comp.value = nil
      elsif conn.last_recv < timeout
        # timed out
        info("client timed out; #{conn.inspect}")
        send_data(entity, "Timed out; closing connection\n")
        conn.close_connection_after_writing
        comp.value = nil
      end
    end
  end
end

