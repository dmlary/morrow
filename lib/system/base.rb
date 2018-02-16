require_relative '../helpers'

module System::Base
  include ::Helpers::Logging

  def send_data(buf, p={})
    entity = p[:entity] || @entity
    conn = entity.get_value(:connection) or
        raise RuntimeError,
            'send_line(%s) failed; entity has no connection' %
                entity.inspect
    conn.send_data(buf)
    entity
  end

  def get_room(entity=nil)
    entity ||= @entity
    location_id = entity.get_value(:location) or return nil
    World.by_id(location_id)
  end

end
