module Morrow
  # commands related to interacting with items; get, put, drop, etc.
  module Command::ActObject
    extend Command

    class << self
      # Pick up an item
      #
      # Syntax: get <item>, get <item> <container>
      #
      def get(actor, arg)
        room = entity_location!(actor)
        item = match_keyword(arg, visible_items(actor, room: room)) or
            command_error("You do not see #{arg.en.a} here.")

        command_error('Your hand passes right through %s!' %
            entity_short(item)) unless entity_corporeal?(item)

        move_entity(entity: item, dest: actor)
        act('%{actor} %{v:pick} up %{item}.', actor: actor, item: item)
      rescue EntityTooHeavy
        command_error('%s is too heavy for you to take.' %
            entity_short(item).capitalize)
      rescue EntityTooLarge
        command_error('Your hands are full.')
      end
    end
  end
end
