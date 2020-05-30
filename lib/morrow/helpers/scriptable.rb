require 'forwardable'
require 'facets/array/average'

# For #act() to conjugate verbs
require 'linguistics'
Linguistics.use :en

module Morrow
  # This file contains helpers that are **SAFE** to use within scripts.  Every
  # method added here will be exposed to scripts.  As such, be certain you're
  # not implementing something that can open the server up to exploit.
  #
  # If you're not sure, add your helper to Morrow::Helpers instead.
  #
  module Helpers::Scriptable
    extend Morrow::Logging

    extend Forwardable
    def_delegators 'Morrow.em', :add_component, :remove_component, :get_component,
        :get_components, :entity_exists?, :entity_exists!

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
      rescue UnknownEntity
        # spawn entity has already been destroyed; continue
      end

      # remove the entity from whatever location it was in
      begin
        if location = entity_location(entity) and
            cont = get_component(location, :container)
          cont.contents.delete(entity)
        end
      rescue UnknownEntity
        # container entity has already been destroyed; continue
      end

      Morrow.entities_to_be_destroyed << entity
    end

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
    # Parameters:
    # * dest: destination entity
    # * entity: entity to be moved
    # * look: run 'look' after the entity has been moved
    # * ignore_limits: ignore container limits when moving
    def move_entity(dest:, entity:, look: false, ignore_limits: false)
      container = get_component!(dest, :container)
      location = get_component!(entity, :location)
      src = location.entity

      raise Morrow::Error, 'cannot move entity into itself' if dest == entity

      if !ignore_limits and entity_corporeal?(entity)

        # When considering volume, we only consider the volume of the entity,
        # not it's contents;  just assume every container is the tardis.
        if max_volume = container.max_volume
          volume = entity_contents_volume(dest)
          volume += entity_volume(entity)
          raise EntityTooLarge if volume > max_volume
        end

        # When considering max weight, we use the cumulative weight of the
        # entity and all of its contents (recursive).  Also, if the source
        # container is inside the destination, don't consider weight limits;
        # the destination is already holding the weight of the entity to
        # be moved.
        if max_weight = container.max_weight and
            (src.nil? or entity_location(src) != dest)
          weight = entity_contents_weight(dest)
          weight += entity_cumulative_weight(entity)
          raise EntityTooHeavy if weight > max_weight
        end
      end

      # remove the entity from any existing location
      src && get_component(src, :container)&.contents.delete(entity)
      remove_component(entity, :teleport)

      # move the entity
      location.entity = dest
      container.contents.unshift(entity)

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
      if buf == 'all'
        raise Command::Error,
            'The "all" modifier is not supported for this command.' unless
                multiple
        return pool.flatten
      end

      raise Error, "unparsable keyword; #{buf}" unless
          buf =~ /^(?:(all)\.|(\d+).)?(.*)$/
      all = !!$1
      index = $2 ? $2.to_i : 1
      keywords = $3.split('-').uniq

      # short circut for invalid indexes < 1
      return multiple ? [] : nil if index < 1

      # ensure the user isn't using 'all.item' when the caller expects only a
      # single item
      raise Command::Error,
          'The "all" modifier is not supported for this command.' if
              all and !multiple

      pool.flatten!

      matches = []
      pool.each do |entity|
        words = get_component(entity, :keywords)&.words or next
        next unless (words & keywords).size == keywords.size
        matches << entity
        break if matches.size == index and !all
      end

      multiple == false ? matches[index - 1] :
        all ? matches : [ matches[index - 1] ].compact
    end

    # Create a new instance of an entity from a base entity, and move it to
    # dest.
    #
    # Arguments:
    #   dest: container Entity to move entity to
    #   base: base Entity to spawn
    def spawn_at(dest:, base:)
      entity = spawn(base: base, area: entity_area(dest))
      move_entity(entity: entity, dest: dest, ignore_limits: true)
      entity
    end

    # spawn
    #
    # Create a new instance of an entity from a base entity
    def spawn(base:, area: nil)
      entity = create_entity(base: base)
      debug("spawning #{entity} from #{base}")

      # if the base was a template, sweep through all of the component fields,
      # and evaluate any Morrow::Function values we find.
      if entity_has_component?(entity, :template)

        entity_components(entity).each do |comp|
          comp.each do |field, value|
            next unless value.is_a?(Morrow::Function)
            comp[field] = value.call(entity: entity, component: comp.class,
                field: field)
          end
        end

        remove_component(entity, :template)
      end

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
    rescue
      destroy_entity(entity) if entity
      raise
    end

    # Send output to entity if they have a connected ConnectionComponent
    def send_to_char(char:, buf:)
      conn_comp = get_component(char, :connection) or return
      return unless conn_comp.buf
      out = conn_comp.buf
      out << buf.to_s
      out << "\n" unless out[-1] == "\n"
      nil
    end

    # Send custom messages to each observer of an action in a room.  This
    # function only supports English in the present tense for the more
    # complicated things.
    #
    # The complexity of this method is that for any act in a room, there are
    # three possible view-points:
    # * The actor (first person; 'You smile at Victim')
    # * A victim (third person; 'Actor smiles at you')
    # * A neutral observer (also, third person; 'Actor smiles at Victim')
    #
    # This method constructs each of these view-points and sends them to the
    # appropriate entities in the room.
    #
    # The format string uses the following syntax:
    # * `%{actor}` short name of the entity in the `:actor` parameter
    # * `%{<param>}` short name for the entity in the named parameter
    # * `%{v:<verb>}` proper conjugation of the verb for the observer.
    # * `%{p:<param>}` pronoun of the entity in the named parameter
    # * `%{poss:<param>}` possessive form of the entity in the named parameter
    #
    # Arguments:
    # * fmt: format string to output to everyone in the room
    #
    # Parameters:
    # * actor: required entity performing the action
    # * in: optional room to perform act in; default is actor location
    # * Any other parameters referenced in format string
    #
    # Examples:
    #   # show an actor picking up a given item
    #   act("%{actor} %{v:pick} up %{item}", actor: actor, item: item)
    #
    #   # an actor smiling at nobody in particular
    #   act("%{actor} %{v:smile} broadly.")
    #
    #   # an actor hugging someone else
    #   act("%{actor} %{v:hug} %{victim} fiercely!", actor: actor,
    #       victim: victim)
    #
    #   # an actor hugging themselves
    #   act("%{actor} %{v:hug} %{victim} fiercely!", actor: actor,
    #       victim: actor)
    def act(fmt, **p)
      raise ArgumentError, 'missing keyword: actor' unless p.has_key?(:actor)

      room = p[:in] || entity_location(p[:actor])
      room_observers(room).each do |observer|
        first = nil
        out = fmt.gsub(/%{(?:([^:}]+):)?([^}]+)}/) do
          op, arg = $1, $2
          second_person = (observer == p[arg.to_sym])

          case op
          when nil
            arg = arg.to_sym
            first ||= p[arg]
            if observer == p[arg]
              'you'
            else
              begin
                entity_short(p[arg])
              rescue UnknownEntity
                p[arg]
              end
            end
          when 'v'
            arg.en.conjugate(:present, observer == first ?
                nil : :third_person_singular)
          when 'p'
            second_person ? 'you' : 'they'
          when 'poss'
            second_person ? 'your' : entity_short(p[arg.to_sym]) + "'s"
          else
            raise Error, "unknown format operator '#{op}' in '#{fmt}'"
          end
        end

        out.gsub!(/^./) { |c| c.upcase }

        send_to_char(char: observer, buf: out)
      end
    end

    # Run a command as the given actor
    def run_cmd(actor, buf)
      name, arg = buf.split(/\s+/, 2)
      return if name.nil?
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
    rescue Command::Error => ex
      send_to_char(char: actor, buf: ex.message)
    end

    # Array of entities within an entity's ContainerComponent
    def entity_contents(entity)
      comp = get_component(entity, :container) or return []
      comp.contents
    end

    # check to see if two entities have the same location
    def entity_present?(actor:, entity:)
      entity_location(actor) == entity_location(entity)
    end

    # raise EntityNotPresent if two entities do not have the same location
    def entity_present!(actor:, entity:)
      raise EntityNotPresent,
          "entity not present: #{entity}, actor: #{actor}" unless
              entity_present?(actor: actor, entity: entity)
    end

    # Return the array of Entities within a Container Entity that are visibile to
    # the actor.  This method also supports a block argument to allow further
    # refinement of which entities should be returned.
    #
    # Examples:
    #   # get the visible items in a chest
    #   visible_contents(actor: leo, cont: chest)
    #
    #   # get the visible entities in a room
    #   visible_contents(actor: leo, cont: entity_location(leo))
    #
    #   # get the visible characters in a room
    #   visible_contents(actor: leo, cont: entity_location(leo)) do |entity|
    #     is_char?(entity)
    #   end
    def visible_contents(actor:, cont:)
      get_component(cont, :container)
          &.contents
          &.select do |entity|
            entity_has_component?(entity, :viewable) and
                (block_given? ? yield(entity) : true)
          end or []
    end

    # return an array of characters within a container that are visible to
    # the actor.
    def visible_chars(actor, room: nil)
      room ||= entity_location(actor)
      visible_contents(actor: actor, cont: room) { |e| is_char?(e) }
    end

    # return the list of inanimate entities within a container that are visible
    # to the actor.
    def visible_objects(actor, room: nil)
      room ||= entity_location(actor)
      visible_contents(actor: actor, cont: room) { |e| !is_char?(e) }
    end

    # return an array of entities in a given room that can observe actions
    # occuring within them.
    def room_observers(room)
      entity_contents(room).select { |e| is_char?(e) }
    end

    # Get all the exits in a room; most likely you want to use visible_exits
    # instead.
    def entity_exits(room)
      exits = get_component(room, :exits) or return []
      exits.get_modified_fields.values
    end

    # get all doors in this entity
    def entity_doors(room)
      exits = get_component(room, :exits) or return []
      exit_directions.inject([]) do |o, dir|
        if exits[dir] && door = exits["#{dir}_door"]
          o << door
        end
        o
      end
    end

    # Returns array of Components for an entity.
    #
    # Note: Most likely you don't need this, and should be using get_view() or
    # get_component() which are both faster.
    def entity_components(entity)
      Morrow.em.entities[entity]&.compact&.flatten or
          raise UnknownEntity, entity
    end

    # entity_location(entity)
    #
    # Get the location for a given entity
    def entity_location(entity)
      get_component(entity, :location)&.entity
    end

    def entity_location!(entity)
      entity_location(entity) or raise Error,
          "entity has no location: #{entity}"
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
      raise Error, "Failed to find component name for #{arg}"
    end

    # entity_area
    #
    # Get the area name from an entity id
    def entity_area(entity)
      meta = get_component(entity, :metadata) or return nil
      meta.area
    end

    # Get the health of an entity; will return nil if the entity does not have
    # health.
    def entity_health(entity)
      get_component(entity, :character)&.health
    end

    # Check if an entity has health as a resource
    def entity_has_health?(entity)
      entity_health(entity) != nil
    end

    # ensure the entity has health
    def entity_has_health!(entity)
      raise InvalidEntity,
          'entity does not have health: %s' % [ entity ] unless
              entity_has_health?(entity)
    end

    # check if the entity is unconscious
    def entity_unconscious?(entity)
      get_component(entity, :character)&.unconscious == true
    end

    # check if the entity is conscious
    def entity_conscious?(entity)
      !entity_unconscious?(entity)
    end

    # check if the entity is incapacitated
    def entity_incapacitated?(entity)
      entity_health(entity) < -5
    end

    # check if the entity is mortally wounded
    def entity_mortally_wounded?(entity)
      entity_health(entity) < -10
    end

    # check if the entity is dead
    def entity_dead?(entity)
      entity_health(entity) < -20
    end

    # get the position of a character
    def entity_position(entity)
      get_component(entity, :character)&.position
    end

    # entity_has_component?
    #
    # Check to see if the entity has a specific component
    def entity_has_component?(entity, component)
      get_components(entity, component).empty? == false
    end

    # Check if an entity has a ClosableComponent and is closed
    def entity_closed?(entity)
      closable = get_component(entity, :closable) or return false
      !!closable.closed
    end

    # close a closable entity
    def close_entity(entity)
      closable = get_component(entity, :closable) or raise ComponentNotPresent
      closable.closed = true
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

    # check if the entity is a character
    def is_char?(entity)
      get_component(entity, :character) != nil
    end

    # check if the entity is container
    def entity_container?(entity)
      get_component(entity, :container) != nil
    end

    # Get the short description for an entity; falls back to entity_keyword if no
    # short was defined.
    def entity_short(entity)
      get_component(entity, :viewable)&.short or "the #{entity_keywords(entity)}"
    end

    # get the long description of an entity
    def entity_long(entity)
      get_component(entity, :viewable)&.long
    end

    # entity_desc
    #
    # Get the desc description for an entity
    def entity_desc(entity)
      get_component(entity, :viewable)&.desc
    end

    # Check to see if the entity is corporeal
    def entity_corporeal?(entity)
      entity_has_component?(entity, :corporeal)
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

    # Get the list of possible exit directions from any room.
    def exit_directions
      @exit_directions ||= %w{ north south east west up down }
    end

    # Begin combat between an actor and a target.
    def enter_combat(actor:, target:)
      raise InvalidEntity, "entity cannot enter combat with itself" if
              actor == target

      entity_present!(actor: actor, entity: target)
      entity_has_health!(target)

      # If the actor isn't already in combat with a target, set them to be
      # targeting the target.
      get_component!(actor, :combat).target ||= target

      # Grab the target's entity, add the actor to the attackers list, and if the
      # target isn't engaged with anyone already, have them target the actor.
      t = get_component!(target, :combat)
      attackers = t.attackers
      attackers << actor unless attackers.include?(actor)
      t.target ||= actor
    end

    # Check to see if an entity is in combat
    def entity_in_combat?(entity)
      combat = get_component(entity, :combat) or return false
      combat.target || !combat.attackers.empty?
    end

    # Damage an entity, and do all the other housekeeping involved with one
    # entity harming another.
    def damage_entity(entity:, actor:, amount:)

      # Entity must have a health resource to be damaged.
      character = get_component(entity, :character)
      raise InvalidEntity, "entity does not have health: #{entity}" if
          character.health.nil?

      modifier = 1.0
      case entity_position(entity)
      when :sitting
        modifier += 0.5
      when :lying
        modifier += 1
      end

      health = character.health -= amount * modifier
      act('%{actor} %{v:hit} %{victim}.', actor: actor, victim: entity)

      # If health dropped below 1, set the position to lying down if the entity
      # is animate
      if entity_dead?(entity)
        act('%{victim} %{v:be} dead!', actor: actor, victim: entity)
        spawn_corpse(entity)
        destroy_entity(entity)
      elsif health < 1
        character.position = :lying
        character.unconscious = true
      end
    end

    # Attempt to hit another entity with an auto-attack
    def hit_entity(actor:, entity:)
      enter_combat(actor: actor, target: entity)

      if rand(100) < 5
        act("%{actor} %{v:miss} %{victim}.", actor: actor, victim: entity)
      elsif entity_conscious?(entity) and
          entity_ability_check?(entity, :dodge) and
          rand(100) < 20
        act('%{victim} %{v:dodge} %{poss:actor} attack!',
            actor: actor, victim: entity)
      else
        damage_entity(actor: actor, entity: entity, amount: 10)
      end
    end

    # Spawn a corpse for the given entity
    def spawn_corpse(entity)
      return unless get_component(entity, :character)

      corpse = spawn_at(dest: entity_location(entity),
          base: 'morrow:obj/remains/corpse')
      get_component(corpse, :keywords)
          .words
          .push(*get_component(entity, :keywords).words)

      entity_contents(entity).each do |item|
        move_entity(dest: corpse, entity: item, ignore_limits: true)
      end

      viewable = get_component(corpse, :viewable)
      viewable.long = 'The corpse of %s is lying here.' % entity_short(entity)

      # corpse will decay in 5 minutes; XXX need longer decay for player corpses.
      get_component!(corpse, :decay).at = now + 5 * 60

      destroy_entity(entity)
    end

    # get the combat target for an entity
    def entity_target(entity)
      get_component(entity, :combat)&.target
    end

    # get an entity's proficiency at an ability
    def entity_proficiency(entity, ability)
      ab = get_component(entity, :abilities)&.send(ability) or return 0
      [ ab[:proficiency] + ab[:proficiency_mod], ab[:proficiency_max] ].min
    end

    # perform a proficiency check for an entity with a given ability
    def entity_ability_check?(entity, ability)
      rand(100) < entity_proficiency(entity, ability)
    end

    # get the weight of an entity
    def entity_weight(entity)
      get_component(entity, :corporeal)&.weight || 0
    end

    # Get the total weight of all entities within the container.  This
    # includes the weight of any entities within containers inside the
    # top-level container.
    def entity_contents_weight(container)
      entity_contents(container).inject(0) do |total,entity|
        total + entity_weight(entity) + entity_contents_weight(entity)
      end
    end

    # Get the cumulative weight of an entity along with the weight of its
    # contents.
    def entity_cumulative_weight(entity)
      entity_weight(entity) + entity_contents_weight(entity)
    end

    # Get the volume of an entity
    def entity_volume(entity)
      get_component(entity, :corporeal)&.volume || 0
    end

    # Get the total volume of all entities within the container.
    def entity_contents_volume(container)
      entity_contents(container).inject(0) do |total,entity|
        total + entity_volume(entity)
      end
    end

    # Update the level of a character based on their class levels.  If the
    # character has no class levels, level will not be modified.
    #
    # This method also returns the updated level.
    def update_char_level(entity)
      char = get_component(entity, :character) or
          raise InvalidEntity, 'not a character: #{entity}'

      max = 0
      char.class_level&.each do |_,v|
        max = v if v > max
      end
      max > 0 ? char.level = max : char.level
    end

    def char_level(entity)
      char = get_component(entity, :character) or
          raise InvalidEntity, 'not a character: #{entity}'
      char.level
    end

    # Update a character's resources, including base value, max value
    def update_char_resources(entity)
      char = get_component(entity, :character) or
          raise InvalidEntity, 'not a character: #{entity}'

      char.health_max = char_health_base(entity) + char.health_modifier
      char.health = char.health_max if char.health > char.health_max
    end

    # Get the base per-level health of the character based on classes.  This
    # method takes in to account per-level and per-class health,
    # multi-classing, and the affect of the constitution bonus.
    def char_health_base(entity)
      char = get_component(entity, :character) or
          raise InvalidEntity, 'not a character: #{entity}'
 
      health = char.class_level&.map do |name, level|
        klass = Morrow.config.classes[name] or
            raise UnknownCharacterClass, 'unknown character class: %s' %
                name.inspect
        comp = get_component(klass, :class_definition) or
            raise ComponentNotPresent,
                "no class definition component found: #{entity}"

        comp.health_func.call(entity: klass, level: level,
            component: :class_definition, field: :health_func)
      end&.average

      (health * char_attr_bonus(entity, :con)).to_i
    end

    # Get the value for a character's attribute.
    def char_attr(entity, attr)
      char = get_component(entity, :character) or
          raise InvalidEntity, 'not a character: #{entity}'
      char['%s_base' % attr] + char['%s_modifier' % attr]
    end

    # Get a character's bonus/reduction based on a given attribute.  The value
    # returned will be a Float where 1.0 means no bonus or reduction.
    #
    # Right now the math comes out to a 1% reduction for every point below 13,
    # and a 1% increase for every point above 13.
    #
    # Examples:
    #   # character with a constitution of 13
    #   char_attr_bonus(char, :con)   # =>  1.0
    #
    #   # character with a constitution of 20
    #   char_attr_bonus(char, :con)   # =>  1.07
    #
    def char_attr_bonus(entity, attr)
      1 + (char_attr(entity, attr) - 13)/100.0
    end

    # Get the :class_definition component for a given class
    def class_def(name)
      entity = Morrow.config.classes[name] or
          raise UnknownCharacterClass, 'unknown character class: %s' %
              name.inspect
      get_component(entity, :class_definition) or
          raise MissingClassDefinition,
              "no class definition component found: #{entity}"
    end

    # get the base entities for this entity
    def entity_base(entity)
      get_component(entity, :metadata)&.base || []
    end
  end
end
