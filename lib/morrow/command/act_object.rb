module Morrow
  # commands related to interacting with items; get, put, drop, etc.
  module Command::ActObject
    extend Command

    class << self
      # Get an item
      #
      # Syntax: get <obj>, get <obj> [from] [my] <container>
      #
      def get(actor, arg)
        room = entity_location!(actor)

        arg =~ %r{^(\S+)(?:\s+from)?(\s+my)?(?:\s+(\S+))?} or
            command_error("unsupported syntax; see 'help get'")
        obj_keyword, my, cont_keyword = $~.captures

        if cont_keyword
          possible_containers = []
          possible_containers += visible_items(actor, room: room) unless my
          possible_containers += visible_items(actor, room: actor)

          cont = match_keyword(cont_keyword, possible_containers) or
              command_error("You do not see #{cont_keyword.en.a} here.")

          command_error('%s is closed.' % entity_short(cont).capitalize) if
              entity_closed?(cont)

          obj = match_keyword(obj_keyword, visible_items(actor, room: cont)) or
              command_error('You do not see %s in %s.' %
                  [ obj_keyword.en.a, entity_short(cont) ])

        else
          obj = match_keyword(obj_keyword, visible_items(actor, room: cont)) or
              command_error("You do not see #{obj_keyword.en.a} here.")
        end

        command_error('Your hand passes right through %s!' %
            entity_short(obj)) unless entity_corporeal?(obj)

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

      # Drop an item
      #
      # Syntax: drop <obj>
      #
      def drop(actor, arg)
        room = entity_location!(actor)

        obj = match_keyword(arg, visible_items(actor, room: actor)) or
            command_error("You do not have #{arg.en.a}.")

        move_entity(entity: obj, dest: room)
        act('%{actor} %{v:drop} %{obj}.', actor: actor, obj: obj)
      rescue EntityWillNotFit
        command_error 'There is no space to drop that here.'
      end
    end
  end
end
