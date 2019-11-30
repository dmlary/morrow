module Command::Look
  extend World::Helpers

  Command.register('look') do |actor, keyword|
    room = actor.get(:location) or fault "actor has no location", actor

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
    when :player_char, :char
      show_char(actor, target)
    else
      fault "look #{keyword}", target
      "not implemented; look <thing>"
    end
  end

  class << self
    def show_room(actor, room)
      return room.pretty_inspect if actor.get(:player_config, :coder)

      exits = room.get(:exits).map do |p_ref|
        passage = p_ref.resolve
        name = exit_name(passage)
        closed = passage.get(:closable, :closed)
        desc = (closed ? '[ &K%s&0 ]' : '%s') % name
        [ name, desc ]
      end.sort_by { |n,d| d }.map(&:last)

      view = room.get_component(:viewable)

      buf = "&W%s&0\n" % room.get(:viewable, :short)
      buf << room.get(:viewable, :long)
      buf << "\n"
      buf << "&WExits: &0%s&0" % exits.join(" ")
      buf << "\n"

      buf
    end

    def show_char(actor, target)
      return target.pretty_inspect if actor.get(:player_config, :coder)

      buf = target.get(:viewable, :full)
      buf << "\n"

      # XXX short is a <RACE>
      # XXX He/She/It is in <CONDITION>
      buf << target.get(:viewable, :short)
      buf << " may be referred to as '&C%s&0'.\n" % target.get(:keywords).join('-')

      # XXX equipment
    end
  end
end
