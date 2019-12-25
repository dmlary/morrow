require 'forwardable'
require 'facets/string/indent'

module World::Helpers
  include Helpers::Logging
  extend Forwardable
  def_delegators :World, :create_entity, :add_component, :remove_component,
      :get_component, :get_components, :get_component!

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

  # destroy_entity
  #
  # Destroy an entity, and update whatever SpawnComponent it may have come
  # from.
  def destroy_entity(entity)
    if spawned = get_component(entity, SpawnedComponent) and
        spawn = get_component(spawned.source, SpawnComponent)
      spawn.active -= 1
      spawn.next_spawn ||= Time.now + spawn.frequency
    end

    em.destroy_entity(entity)
  end

  # Get the cardinal direction from the passage, or the first keyword
  def exit_name(passage)
    keywords = [ passage.get(:keywords, :words) ].flatten
    (keywords & World::CARDINAL_DIRECTIONS).first or keywords.first
  end

  # place one entity inside another entity's contents
  def move_entity(entity, dest)
    container = get_component!(dest, :container)
    location = get_component!(entity, :location)

    if old = location.entity and src = get_component(old, :container)
      debug "moving #{entity} from #{old} to #{dest}"
      src.contents.delete(entity)
    else
      debug "moving #{entity} to #{dest}"
    end

    location.entity = dest
    container.contents << entity
  end

  # get a/all entities from ++pool++ that have keywords that match our
  # the provided ++keyword++
  #
  # Arguments:
  #   ++buf++ String; "sword", "sharp-sword", "3.sword", "all.sword"
  #   ++pool++ Entity ids
  #
  # Parameters:
  #   ++multiple++ set to true if more than one match permitted
  #
  # Return:
  #   when multiple: Array of matching entities in ++pool++
  #   when not multiple: first entity in ++pool++ that matches
  #
  def match_keyword(buf, *pool, multiple: false)

    fault "unparsable keyword; #{buf}" unless buf =~ /^(?:(all|\d+)\.)?(.*)$/
    index = $1
    keywords = $2.split('-').uniq

    # ensure the user isn't using 'all.item' when the caller expects only a
    # single item
    raise Command::SyntaxError,
        "'#{buf}' is not a valid target for this command" if
            index == 'all' and !multiple

    pool.flatten!

    # if the user hasn't specified an index, or the caller hasn't specified
    # that they want multiple matches, do the simple find here to grab and
    # return the first match
    if index.nil? and multiple != true
      return pool.find do |entity|
        comp = get_component(entity, :keywords) or next false
        (comp.words & keywords).size == keywords.size
      end
    end

    # Anything else requires us to have the full matches list
    matches = pool.select do |entity|
      comp = get_component(entity, :keywords) or next false
      (comp.words & keywords).size == keywords.size
    end

    return matches if index.nil? or index == 'all'

    index = index.to_i - 1
    multiple ? [ matches[index] ].compact : matches[index]
  end

  # spawn_at
  #
  # Create a new instance of an entity from a base entity, and move it to dest.
  #
  # Arguments:
  #   dest: container Entity to move entity to
  #   base: base Entity to spawn
  def spawn_at(dest: nil, base: nil)
    raise ArgumentError, 'no dest' unless dest
    raise ArgumentError, 'no base' unless base

    entity = spawn(base: base, area: entity_area(dest))
    move_entity(entity, dest)
    entity
  end

  # spawn
  #
  # Create a new instance of an entity from a base entity
  def spawn(base: nil, area: nil)
    entity = create_entity(base: base, id: area ? "#{area}:" : nil)
    debug("spawning #{entity} from #{base}")
    remove_component(entity, ViewExemptComponent)

    if container = get_component(entity, ContainerComponent)
      bases = container.contents.clone
      container.contents = bases.map { |b| spawn_at(dest: entity, base: b ) }
    end
    if spawn_point = get_component(entity, SpawnPointComponent)
      bases = spawn_point.list.clone
      spawn_point.list = bases.map { |b| spawn(base: b, area: area) }
    end

    entity
  end

  # visible_contents
  #
  # Return the array of Entities within a Container Entity that are visibile to
  # the actor.
  def visible_contents(actor: nil, cont: nil)
    raise ArgumentError, 'no actor' unless actor
    raise ArgumentError, 'no container' unless cont

    # XXX handle visibility checks at some point
    comp = get_component(cont, ContainerComponent) or return []
    comp.contents.select { |c| get_component(c, ViewableComponent) }
  end

  # visible_exits
  #
  # Return the array of exits visible to actor in room.
  def visible_exits(actor: nil, room: nil)
    raise ArgumentError, 'no actor' unless actor
    raise ArgumentError, 'no room' unless room

    # XXX handle visibility checks at some point
    exits = get_component(room, ExitsComponent) or return []
    exits.list.clone
  end

  # entity_location(entity)
  #
  # Get the location for a given entity
  def entity_location(entity)
    loc = get_component(entity, LocationComponent) or return nil
    loc.entity
  end

  # entity_desc
  #
  # Get a human-readable description for an entity
  def entity_desc(entity)
    desc = '%s: ' % entity
    if words = entity_keywords(entity)
      desc << "keywords='#{words}', "
    else
      desc << "keywords=nil, "
    end

    loc = entity_location(entity)
    desc << 'loc=%s, ' % loc.inspect
    components = em.entities[entity].compact.flatten
        .map { |c| component_name(c) }
    desc << 'comps=%s' % components.inspect
    desc
  end

  # player_config
  #
  # Get a specific config value from a entity's PlayerConfigComponent
  def player_config(player, option)
    config = get_component(player, PlayerConfigComponent) or return nil
    config.send(option)
  end

  # entity_keywords
  #
  # Get keywords for an entity
  def entity_keywords(entity)
    keywords = get_component(entity, KeywordsComponent) or return nil
    words = keywords.words
    words = [ words ] unless words.is_a?(Array)
    words.join('-')
  end

  # component_name
  #
  # Given a Component instance or class, return the name
  def component_name(arg)
    arg = arg.class if arg.is_a?(Component)
    arg.to_s.snakecase.sub(/_component$/, '').to_sym
  end

  # entity_area
  #
  # Get the area name from an entity id
  def entity_area(entity)
    entity.split(':',2).first
  end

  # entity_closed?
  #
  # Check if an entity has a ClosableComponent and is closed
  def entity_closed?(entity)
    closable = get_component(entity, ClosableComponent) or return false
    !!closable.closed
  end

  # entity_locked?
  #
  # Check if an entity has a ClosableComponent and is locked
  def entity_locked?(entity)
    closable = get_component(entity, ClosableComponent) or return false
    !!closable.locked
  end

  # entity_short
  #
  # Get the short description for an entity
  def entity_short(entity)
    view = get_component(entity, ViewableComponent) or return nil
    view.short
  end
end
