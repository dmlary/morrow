class System::Base
  def send_data(entity, buf)
    conn = entity.get_value(:connection) or
        raise RuntimeError,
            'send_line(%s) failed; entity has no connection' %
                entity.inspect
    conn.send_data(buf)
    entity
  end
end
