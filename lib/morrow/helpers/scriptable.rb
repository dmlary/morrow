require 'forwardable'

# Morrow::Helpers::Scriptable
#
# This file contains helpers that are **SAFE** to use within scripts.  Every
# method added here will be exposed to scripts.  As such, be certain you're not
# implementing something that can open the server up to exploit.
#
# If you're not sure, add your helper to Morrow::Helpers instead.
#
module Morrow::Helpers::Scriptable
  extend Morrow::Logging

  extend Forwardable
  def_delegators 'Morrow.em', :add_component, :remove_component, :get_component,
      :get_components, :entity_exists?, :entity_exists!

  # get_component!
  #
  # Get a unique component for the entity.  If one does not yet exist, it
  # will create the component.  Will raise an exception if ++type++ is a
  # non-unique component.
  def get_component!(entity, type)
    Morrow.em.get_component(entity, type) or
        Morrow.em.add_component(entity, type)
  end

  # Wrapper around EntityManager#create_entity that keeps our metadata
  # component up-to-date.
  def create_entity(id: nil, base: [], components: [])
    base = [ base ] unless base.is_a?(Array)
    entity = Morrow.em
        .create_entity(id: id, base: base, components: components)
    get_component!(entity, :metadata).base = base
    entity
  end

  # destroy_entity
  #
  # Destroy an entity, and update whatever SpawnComponent it may have come
  # from.
  def destroy_entity(entity)
    debug("destroying entity #{entity}")

    # update any spawn point that this entity is going away
    begin
      if source = get_component(entity, :metadata)&.spawned_by and
          spawn = get_component(source, :spawn)
        spawn.active -= 1
        spawn.next_spawn ||= now + spawn.frequency
      end
    rescue Morrow::EntityManager::UnknownId
      # spawn entity has already been destroyed; continue
    end

    # remove the entity from whatever location it was in
    begin
      if location = entity_location(entity) and
          cont = get_component(location, :container)
        cont.contents.delete(entity)
      end
    rescue Morrow::EntityManager::UnknownId
      # container entity has already been destroyed; continue
    end

    Morrow.em.destroy_entity(entity)
  end

  # now
  #
  # Get the current time according to the engine.  Note, this is **only**
  # updated each time Morrow#update() is called.
  def now
    Morrow.update_start_time
  end

  # Get the cardinal direction from the passage, or the first keyword
  def exit_name(passage)
    keywords = [ passage.get(:keywords, :words) ].flatten
    (keywords & World::CARDINAL_DIRECTIONS).first or keywords.first
  end

  # Move an entity into the ContainerComponent of another entity.  If the
  # entity being moved already resides within another entity's
  # ContainerComponent, first remove it from it's existing container.
  #
  # This method will also fire the following hooks in order:
  #   * <move the entity>
  #   * on_exit
  #   * on_enter
  #
  def move_entity(dest:, entity:, look: false)
    container = get_component!(dest, :container)
    location = get_component!(entity, :location)
    src = location.entity

    # I apologize, but this is gonna be ugly and may be premature optimization.
    #
    # For corporeal entities, we need to first check if the entity will fit in
    # the destination (by volume & weight), but only if the container has a
    # limit on at least one of volume or weight.  We only want to sweep through
    # the entities once, so we do all of this at once.  Thus, ugly.
    if corp = get_component(entity, :corporeal) and
        (max_vol = container.max_volume or max_weight = container.max_weight)

      vol, weight = container.contents
          .inject([corp.volume || 0, corp.weight || 0]) do |(v,w),e|
        if c = get_component(e, :corporeal)
          v += c.volume || 0
          w += c.weight || 0
        end
        [v, w]
      end

      return :full if (max_vol && vol > max_vol) ||
          (max_weight && weight > max_weight)
    end

    # remove the entity from any existing location
    src && get_component(src, :container)&.contents.delete(entity)
    remove_component(entity, :teleport)

    # move the entity
    location.entity = dest
    container.contents << entity

    # perform the look for the entity if it was requested
    # XXX kludge for right now
    run_cmd(entity, 'look') if look

    # schedule the teleport if the dest is a teleporter
    if teleporter = get_component(dest, :teleporter)
      tele = get_component!(entity, :teleport)
      delay = teleporter.delay
      delay = rand(teleporter.delay) if delay.is_a?(Range)
      tele.time = now + delay
      tele.teleporter = dest
    end

    # fire on-enter hook
    container.on_enter&.call(args: { entity: entity, here: dest })

    nil
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
  def spawn_at(dest:, base:)

    entity = spawn(base: base, area: entity_area(dest))
    move_entity(entity: entity, dest: dest)
    entity
  end

  # spawn
  #
  # Create a new instance of an entity from a base entity
  def spawn(base:, area: nil)
    entity = create_entity(base: base)
    debug("spawning #{entity} from #{base}")
    remove_component(entity, :template)
    get_component!(entity, :metadata).area = area

    if container = get_component(entity, :container)
      bases = container.contents.clone
      container.contents = bases.map { |b| spawn_at(dest: entity, base: b ) }
    end
    if spawn_point = get_component(entity, :spawn_point)
      bases = spawn_point.list.clone
      spawn_point.list = bases.map { |b| spawn(base: b, area: area) }
    end

    entity
  end

  # send_to_char
  #
  # Send output to entity if they have a connected ConnectionComponent
  def send_to_char(char:, buf:)
    conn_comp = get_component(char, :connection) or return
    return unless conn_comp.buf
    conn_comp.buf << buf.to_s
    nil
  end

  # Run a command as the given actor
  def run_cmd(actor, buf)
    name, arg = buf.split(/\s+/, 2)
    arg = nil if arg && arg.empty?
    name = name.strip.chomp.downcase

    cmds = Morrow.config.commands
    cmd = cmds[name] || begin
        cmds.values
            .select { |c| c.name.start_with?(name) }
            .max_by { |c| c.priority }
    end

    cmd ? cmd.handler.call(actor, arg) :
        send_to_char(char: actor, buf: "unknown command: #{name}")
  rescue Morrow::Command::Error => ex
    send_to_char(char: actor, buf: ex.message)
  end

  # Array of entities within an entity's ContainerComponent
  def entity_contents(entity)
    comp = get_component(entity, :container) or return []
    comp.contents
  end

  # Return the array of Entities within a Container Entity that are visibile to
  # the actor.
  def visible_contents(actor:, cont:)
    get_component(cont, :container)
        &.contents
        &.select { |e| entity_has_component?(e, :viewable) } or []
  end

  # Get all the exits in a room; most likely you want to use visible_exits
  # instead.
  def entity_exits(room)
    exits = get_component(room, :exits) or return []
    exits.get_modified_fields.values
  end

  # Return the array of exits visible to actor in room.
  def visible_exits(actor:, room:)

    # XXX handle visibility checks at some point

    exits = get_component(room, :exits) or return []
    exits.class.fields.map do |dir,_|
      ex = exits.send(dir) or next
      next if entity_closed?(ex) and entity_concealed?(ex)
      ex
    end.compact
  end

  # Returns array of Components for an entity.
  #
  # Note: Most likely you don't need this, and should be using get_view() or
  # get_component() which are both faster.
  def entity_components(entity)
    Morrow.em.entities[entity].compact
  end

  # entity_location(entity)
  #
  # Get the location for a given entity
  def entity_location(entity)
    loc = get_component(entity, :location) or return nil
    loc.entity
  end

  # player_config
  #
  # Get a specific config value from a entity's PlayerConfigComponent
  def player_config(player, option)
    config = get_component(player, :player_config) or return nil
    config.send(option)
  end

  # entity_keywords
  #
  # Get keywords for an entity
  def entity_keywords(entity)
    keywords = get_component(entity, :keywords) or return nil
    words = keywords.words
    words = [ words ] unless words.is_a?(Array)
    words.join('-')
  end

  # component_name
  #
  # Given a Component instance or class, return the name
  def component_name(arg)
    Morrow.config.components.each { |n,c| return n if arg.is_a?(c) }
    raise Morrow::Error, "Failed to find component name for #{arg}"
  end

  # entity_area
  #
  # Get the area name from an entity id
  def entity_area(entity)
    meta = get_component(entity, :metadata) or return nil
    meta.area
  end

  # entity_has_component?
  #
  # Check to see if the entity has a specific component
  def entity_has_component?(entity, component)
    get_components(entity, component).empty? == false
  end

  # entity_closed?
  #
  # Check if an entity has a ClosableComponent and is closed
  def entity_closed?(entity)
    closable = get_component(entity, :closable) or return false
    !!closable.closed
  end

  # entity_locked?
  #
  # Check if an entity has a ClosableComponent and is locked
  def entity_locked?(entity)
    closable = get_component(entity, :closable) or return false
    !!closable.locked
  end

  # entity_concealed?
  #
  # Check if an entity has a ConcealedComponent and it has not been revealed
  def entity_concealed?(entity)
    concealed = get_component(entity, :concealed) or return false
    !concealed.revealed
  end

  # entity_flying?
  def entity_flying?(entity)
    # XXX fixup once we have affects
    false
  end

  # check if the entity is animate
  def entity_animate?(entity)
    get_component(entity, :animate) != nil
  end

  # check if the entity is container
  def entity_container?(entity)
    get_component(entity, :container) != nil
  end

  # entity_short
  #
  # Get the short description for an entity
  def entity_short(entity)
    get_component(entity, :viewable)&.short
  end

  # entity_desc
  #
  # Get the desc description for an entity
  def entity_desc(entity)
    get_component(entity, :viewable)&.desc
  end

  # entity_volume
  #
  # Get the volume for an entity
  def entity_volume(entity)
    get_component(entity, :corporeal)&.volume || 0
  end

  # entity_weight
  #
  # Get the weight for an entity
  def entity_weight(entity)
    get_component(entity, :corporeal)&.weight || 0
  end
end
