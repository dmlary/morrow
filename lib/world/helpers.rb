module World::Helpers
  def get_room(entity=nil)
    entity ||= @entity
    location_id = entity.get(:location) or return nil
    World.by_id(location_id)
  end

  # Move ++entity_id++ with ++location++ component into ++dest_id++
  def move_to_location(entity_id, dest_id)
    dest = World.by_id(dest_id)
    entity = World.by_id(entity_id)
    source = World.by_id(entity.get(:location))

    source.get(:contents).delete(entity_id) if source
    entity.set(:location, dest_id)
    dest.get(:contents).push(entity_id)
  end
end
