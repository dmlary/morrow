module Morrow
  # commands related to interacting with items; get, put, drop, etc.
  module Command::ActObject
    extend Command

    class << self
      # Get an item
      #
      # Syntax:
      #   get <object>
      #   get 2.<object>
      #   get all.<object>
      #   get all
      #   get <object> [from] [my] <container>
      #   get 2.<object> [from] [my] <container>
      #   get all.<object> [from] [my] <container>
      #   get all [from] [my] <container>
      #
      def get(actor, arg)
        conscious!(actor)

        room = entity_location!(actor)

        arg =~ %r{^(\S+)(?:\s+from)?(\s+my)?(?:\s+(\S+))?} or
            command_error("unsupported syntax; see 'help get'")
        obj_keyword, my, cont_keyword = $~.captures

        if cont_keyword
          possible_containers = []
          possible_containers += visible_objects(actor, room: room) unless my
          possible_containers += visible_objects(actor, room: actor)

          cont = match_keyword(cont_keyword, possible_containers) or
              command_error("You do not see #{cont_keyword.en.a} here.")

          command_error('%s is closed.' % entity_short(cont).capitalize) if
              entity_closed?(cont)

          cont_objs = visible_objects(actor, room: cont)
          objs = match_keyword(obj_keyword, cont_objs, multiple: true)

          command_error('You do not see %s in %s.' %
                  [ obj_keyword.en.a, entity_short(cont) ]) if objs.empty?

        else
          objs = match_keyword(obj_keyword, visible_objects(actor, room: cont),
              multiple: true)
          command_error("You do not see #{obj_keyword.en.a} here.") if
              objs.empty?
        end

        objs.each do |obj|
          unless entity_corporeal?(obj)
            send_to_char(char: actor,
                buf: "Your hand passes right through #{entity_short(obj)}.")
            next
          end

          move_entity(entity: obj, dest: actor)

          if cont
            act('%{actor} %{v:get} %{obj} from %{cont}.',
                actor: actor, obj: obj, cont: cont)
          else
            act('%{actor} %{v:pick} up %{obj}.', actor: actor, obj: obj)
          end
        rescue EntityTooHeavy
          command_error('%s is too heavy for you to carry.' %
              entity_short(obj).capitalize)
        rescue EntityTooLarge
          command_error('Your hands are full.')
        end
      end

      # Drop an object
      #
      # Syntax: drop <obj>
      #
      def drop(actor, arg)
        conscious!(actor)

        room = entity_location!(actor)

        matches = match_keyword(arg, visible_objects(actor, room: actor),
            multiple: true)
        command_error("You do not have #{arg.en.a}.") if matches.empty?

        matches.each do |obj|
          move_entity(entity: obj, dest: room)
          act('%{actor} %{v:drop} %{obj}.', actor: actor, obj: obj)
        rescue EntityWillNotFit
          command_error 'There is no space to drop that here.'
        end
      end

      # Put an object into a container
      #
      # Syntax: put <obj> [my] <container>
      #
      def put(actor, arg)
        conscious!(actor)

        room = entity_location!(actor)

        arg =~ %r{^(\S+)(\s+my)?(?:\s+(\S+))?} or
            command_error("unsupported syntax; see 'help put'")
        obj_keyword, my, cont_keyword = $~.captures

        matches = match_keyword(obj_keyword,
            visible_objects(actor, room: actor),
            multiple: true)
        command_error("You do not have #{arg.en.a}.") if matches.empty?

        possible_containers = []
        possible_containers += visible_objects(actor, room: room) unless my
        possible_containers += visible_objects(actor, room: actor)

        cont = match_keyword(cont_keyword, possible_containers) or
            command_error("You do not see #{cont_keyword.en.a} here.")

        command_error('%s is closed.' % entity_short(cont).capitalize) if
            entity_closed?(cont)

        matches.each do |obj|
          next if obj == cont
          move_entity(entity: obj, dest: cont)
          act('%{actor} %{v:put} %{obj} in %{cont}.',
              actor: actor, obj: obj, cont: cont)
        rescue EntityTooLarge
          command_error '%s will not fit in %s.' %
              [ entity_short(obj).capitalize, entity_short(cont) ]
        rescue EntityTooHeavy
          command_error '%s is too heavy to go in %s.' %
              [ entity_short(obj).capitalize, entity_short(cont) ]
        end
      end
    end
  end
end
