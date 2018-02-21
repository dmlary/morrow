require 'facets/string/indent'

module World::Helpers
  # raise an exception with a message, and all manner of extra data
  #
  # Arguments:
  #   ++msg++ Message to include in the RuntimeError exception
  #   ++data++ Additional context data for the exception; ex.data
  #
  # Return: None; exception raised
  #
  def fault(msg, *data)
    ex = World::Fault.new(msg, *data)
    ex.set_backtrace(caller)
    raise(ex)
  end

  def get_room(entity)
    id = entity.get(:location) or return nil
    room = World.by_id(id) or missing_entity(location: id, entity: entity)
    room
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

  # get a/all entities from ++pool++ that have keywords that match our
  # the provided ++keyword++
  #
  # Arguments:
  #   ++buf++ String; "sword", "sharp-sword", "3.sword", "all.sword"
  #   ++pool++ Entity instances, or Entity id's
  #
  # Parameters:
  #   ++multiple++ set to true if more than one match permitted
  #
  # Return:
  #   when multiple: Array of matching entities in ++pool++
  #   when not multiple: first entity in ++pool++ that matches
  #
  def match_keyword(buf, *pool)
    p = pool.last.is_a?(Hash) ? pool.pop : {}

    fault "unparsable keyword; #{buf}" unless buf =~ /^(?:(all|\d+)\.)?(.*)$/
    index = $1
    keywords = $2.split('-').uniq

    # ensure the user isn't using 'all.item' when the caller expects only a
    # single item
    raise Command::SyntaxError,
        "'#{buf}' is not a valid target for this command" if
            index == 'all' and !p[:multiple]

    # if the user hasn't specified an index, or the caller hasn't specified
    # that they want multiple matches, do the simple find here to grab and
    # return the first match
    if index.nil? and p[:multiple] != true
      return World.by_id(pool.flatten).find do |entity|
        (entity.get(:viewable, :keywords) & keywords).size == keywords.size
      end
    end

    # Anything else requires us to have the full matches list
    matches = World.by_id(pool.flatten).select do |entity|
      (entity.get(:viewable, :keywords) & keywords).size == keywords.size
    end

    return matches if index.nil? or index == 'all'

    index = index.to_i - 1
    p[:multiple] ? [ matches[index] ].compact : matches[index]
  end
end
