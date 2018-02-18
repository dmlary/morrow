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

  # Move ++entity_id++ with ++location++ component into ++dest_id++
  def move_to_location(entity_id, dest_id)
    dest = World.by_id(dest_id)
    entity = World.by_id(entity_id)
    source = World.by_id(entity.get_value(:location))

    source.get(:contents).value.delete(entity_id) if source
    entity.set(:location, dest_id)
    dest.get(:contents).value.push(entity_id)
  end
end
