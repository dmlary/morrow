require 'facets/string/indent'

module World::Helpers
  def get_room(entity=nil)
    entity ||= @entity
    location_id = entity.get(:location) or return nil
    World.by_id(location_id)
  end

  # Move ++entity_id++ with ++location++ component into ++dest_id++
  def move_to_location(entity, dest)
    dest = World.by_id(dest)
    entity = World.by_id(entity)
    source = World.by_id(entity.get(:location))

    source.get(:contents).delete(entity.id) if source
    entity.set(:location, dest.id)
    dest.get(:contents).push(entity.id)
  end

  # Log any missing entities
  def missing_entity(p={})
    p.merge!(stack: caller[0,5])
    buf  = "Unknown entity id found:\n"
    buf << p.pretty_inspect.indent(4)
    warn(buf)
    true
  end
end
