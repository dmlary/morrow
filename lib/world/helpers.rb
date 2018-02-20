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

  # Log missing entities/entity id's that don't resolve in the world
  def missing_entity(p={})
    p.merge!(stack: caller[0,5])
    buf  = "Unknown entity id found:\n"
    buf << p.pretty_inspect.indent(4)
    warn(buf)
    true
  end

  # get all things within some scope that have a given keyword/keywords
  # Return an Array of Entity instances that match the supplied keywords
  #
  # Arguments:
  #   ++keywords++ Array of keywords, or single keyword
  #   ++entities++ Array of Entities or Entity ID's
  #
  # Returns:
  #   Array of Entity instances from ++entities++ that contain all
  #   keywords in ++keywords++
  def match_keywords(keywords, entities)
    keywords = [ keywords ].flatten
    World.by_id(entities).select do |entity|
      entity.get(:viewable, :keywords) & keywords == keywords
    end
  end
end
