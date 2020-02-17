module Morrow::Command::Spawn
  extend Morrow::Command

  class << self
    # Spawn a new entity in the current room
    #
    # Syntax: spawn <template id>
    #
    def spawn(actor, arg)
      command_error 'What would you like to spawn?' unless arg
      id = Morrow::Helpers.spawn_at(dest: entity_location(actor), base: arg)
      send_to_char(char: actor,
          buf: 'You wave your hand and %s appears.' % entity_short(id))
    rescue Morrow::UnknownEntity
      command_error 'That is not a valid id.'
    end
  end
end
