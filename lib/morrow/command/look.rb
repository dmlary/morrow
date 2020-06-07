module Morrow::Command::Look
  extend Morrow::Command

  class << self

    # Examine the world around you
    #
    # Syntax: look, look <character>, look <item>, look self, look in <item>
    #
    def look(actor, arg)
      room = entity_location(actor) or fault("actor has no location: #{actor}")
      into = false

      dir = exit_directions.find { |d| d.start_with?(arg) } if arg

      target ||= case arg
        when nil, ''
          room
        when 'self', 'me'
          actor
        when /^\s*in\s(.*?)$/
          into = true
          match_keyword($1,
              visible_contents(actor: actor, cont: room),
              visible_contents(actor: actor, cont: actor))
        else
          match_keyword(arg,
              visible_contents(actor: actor, cont: room),
              entity_doors(room),
              visible_contents(actor: actor, cont: actor))
        end

      command_error 'You do not see that here.' unless dir or
          (target and viewable = get_component(target, :viewable))

      out = ''

      formatter = dir ? :exit : (into ? :into : viewable.formatter.to_sym)

      case formatter
      when :into
        command_error 'You cannot look into that.' unless viewable.contents
        command_error 'It is closed.' if entity_closed?(target)

        out << "&W%s&0:\n" % viewable.short
        out << (format_contents(actor, target, :short) || 'It is empty.')

      when :room
        out << "&W%s&0\n" % viewable.short
        out << "%s\n" % viewable.desc
        out << format_exits(target)
        out << (format_contents(actor, target, :long) || '')

      when :char, :obj
        out << "%s\n" % viewable.desc if viewable.desc
        out << "%s %s.\n" %
            [ entity_short(target), entity_health_status(target) ] if
                is_char?(target)
        out << "%s may be referred to as '&W%s&0'." %
            [ viewable.short, entity_keywords(target) ]

      when :exit
        out << format_exit(room: room, dir: dir, actor: actor)
      else
        out << "%s\n" % viewable.desc
      end

      out.chomp!
      send_to_char(char: actor, buf: out)
    end

    private

    # return a String representing what a given actor sees when looking at a
    # specific exit.
    def format_exit(dir:, room:, actor:)

      # patch up direction for better output
      dirward = case dir
          when 'up', 'down'
            "#{dir}ward"
          else
            "to the #{dir}"
          end

      return "You look #{dirward}, but see nothing special." unless
          exits = get_component(room, :exits) and exits[dir]

      return "You can travel #{dirward}." unless
          door = exits["#{dir}_door"] and
              closable = get_component(door, :closable)

      door_short = entity_short(door).capitalize

      if closable.closed
        if entity_concealed?(door)
          "You look #{dirward}, but see nothing special."
        else
          "#{door_short} #{dirward} is closed."
        end
      else
        "#{door_short} #{dirward} is open."
      end
    end

    # return a String describing the contents of an entity
    #
    # @param actor [String] entity looking inside the container
    # @param target [String] entity that is being looked inside; has a
    #   container component
    # @param method [Symbol] viewable component field to show for each
    #   entity in the target
    # @return [String] human-readable contents of the target entity
    def format_contents(actor, target, method)
      buf = visible_contents(actor: actor, cont: target)
          .inject('') do |out,entity|
        next out if entity == actor or
            !line = get_component(entity, :viewable)[method]
        out << "&%s%s&0\n" % [ is_char?(entity) ? 'C' : 'c', line ]
      end

      buf.empty? ? nil : buf
    end

    # construct the string shown by autoexit when looking at a room
    def format_exits(room)
      buf = ''

      if exits = get_component(room, :exits)
        exit_directions.each do |dir|
          next unless exits[dir]

          if door = exits["#{dir}_door"]
            closed = entity_closed?(door)
            hidden = entity_concealed?(door)
          end

          next if closed and hidden
          buf << (closed ? '&B[ %s ]&W ' : '%s ') % dir
        end
      end

      buf = 'none!' if buf.empty?

      "&WExits: %s&0\n" % buf
    end
  end
end
