module Command::Look
  extend World::Helpers

  Command.register('look') do |actor, keyword|
    room = get_room(actor) or fault "actor has invalid location", actor

    target = if keyword.nil? or keyword.empty?
      room
    elsif keyword == 'self' or keyword == 'me'
      target = actor
    else
      match_keyword(keyword, room.get(:contents), actor.get(:contents))
    end

    next "You do not see that here." unless target

    case target.type
    when :room
      show_room(actor, target)
    when :player, :npc
      show_char(actor, target)
    else
      fault "look #{keyword}", target
      "not implemented; look <thing>"
    end
  end

  class << self
    def show_room(actor, room)
      room = World.by_id(room)

      return room.pretty_inspect if actor.get(:config_options, :coder)

      # exits = room.get_component(:exit, true).map { |e| e.get(:direction) }
      # exits = [ 'none' ] if exits.empty?
      exits = [ 'none' ]

      view = room.get_component(:viewable)

      buf = "&W%s&0\n" % view.get(:short)
      buf << view.get(:description)
      buf << "\n"
      buf << "&CExits: %s&0" % exits.join(" ")
      buf << "\n"

      # Loop through the contents of the room
      World.by_id(room.get(:contents)) do |id, entity|
        missing_entity(actor: actor, component: :contents, id: id) and
            next unless entity

        # Visualize yourself in a room-- wait, no, that's not what we're doing
        next if entity == actor

        if view = entity.get_component(:viewable)
          buf << view.get(:long) or entity.pretty_inspect
          buf << "\n"
        end
      end
      buf
    end

    def show_char(actor, target)
      char = World.by_id(target)
      return char.pretty_inspect if actor.get(:config_options, :coder)

      view = char.get_component(:viewable)
      buf  = ""

      if desc = view.get(:description)
        buf << desc
        buf << "\n"
      else
        buf << "You see nothing special about them.\n"
      end

      # XXX short is a <RACE>
      # XXX He/She/It is in <CONDITION>
      buf << view.get(:short)
      buf << " may be referred to as '&C%s&0'.\n" % view.get(:keywords).join('-')

      # XXX equipment
    end
  end
end
