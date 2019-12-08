module Command::Look
  extend World::Helpers

  Command.register('look') do |actor, arg|
    room = actor.get(LocationComponent, :ref) or
        fault "actor has no location", actor
    show_contents = false

    target = case arg
      when nil, ""
        room.entity
      when "self", "me"
        actor
      when /^in\s(.*?)$/
        show_contents = true
        match_keyword($1, 
          room.get(:exits, :list),
          room.get(:container, :contents),
          actor.get(:container, :contents))
      else
        match_keyword(arg,
            room.get(:exits, :list),
            room.get(:container, :contents),
            actor.get(:container, :contents))
      end

    next "You do not see that here." unless target &&
        target.has_component?(ViewableComponent)

    return target.pretty_inspect if actor.get(:player_config, :coder)

    format = target.get(:viewable, :format)
    case format
    when "room"
      show_room(actor, target)
    when "character"
      show_char(actor, target)
    when 'object'
      if show_contents
        show_contents(actor, target)
      else
        show_obj(actor, target)
      end
    else
      fault "look #{arg}", format, target
      "not implemented; look <thing>"
    end
  end

  class << self
    def show_room(actor, room)
      exits = room.get(:exits, :list).map do |p_ref|
        passage = p_ref.entity
        name = exit_name(passage)
        closed = passage.get(:closable, :closed)
        desc = (closed ? '[ &K%s&0 ]' : '%s') % name
        [ name, desc ]
      end.sort_by { |n,d| d }.map(&:last)

      title, desc = room.get(ViewableComponent, :short, :desc)

      buf = "&W%s&0\n" % title
      buf << desc
      buf << "\n"
      buf << "&WExits: &0%s&0" % exits.join(" ")
      buf << "\n"

      room.get(:container, :contents).each do |ref|
        entity = ref.entity
        next if entity == actor   # you can't see yourself in the room
        if long = entity.get(:viewable, :long)
          buf << long
          buf << "\n"
        end
      end

      buf
    end

    def show_char(actor, target)
      buf = ""
      buf << target.get(:viewable, :long)
      buf << "\n"

      # XXX short is a <RACE>
      # XXX He/She/They/It is in <CONDITION>
      buf << target.get(:viewable, :short)
      buf << " may be referred to as '&C%s&0'.\n" % target.get(:keywords).join('-')

      # XXX equipment
    end

    def show_obj(actor, target)
      buf = ""
      if long = target.get(:viewable, :desc)
        buf << long
        buf << "\n" unless buf[-1] == "\n"
      end

      buf << target.get(:viewable, :short)
      buf << " may be referred to as '&C%s&0'.\n" % target.get(:keywords).join('-')
    end

    def show_contents(actor, target)
      buf = ""
      buf << target.get(:viewable, :short)

      contents = target.get(:container, :contents) or
          return "#{buf} is not a container."
      
      return "#{buf} is closed." if target.get(:closable, :closed)
  
      if contents.empty?
        return buf << " is empty"
      end

      buf << ":\n"
      contents.each do |ref|
        if short = ref.entity.get(:viewable, :short)
          buf << "  "
          buf << short
          buf << "\n"
        end
      end
      buf
    end
  end
end
