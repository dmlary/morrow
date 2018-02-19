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

      # XXX need a safe way to pull all the entity ids from an array, map them
      # to entities, and provide an enumerator.  Also, if any entity id doesn't
      # resolve, throw a warning and remove the id from the array.
      room.get(:contents).each do |entity_id|
        entity = World.by_id(entity_id) or next
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
