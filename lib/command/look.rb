module Command::Look
  extend World::Helpers

  Command.register('look') do |actor, target|
    target ||= get_room(actor)

    # XXX target lookup by keyword

    case target.type
    when :room
      look_room(actor, target)
    else
      "not implemented; look <thing>"
    end
  end


  class << self
    def look_room(actor, room)
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
  end
end
