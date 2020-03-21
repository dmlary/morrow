module Morrow::Command::Goto
  extend Morrow::Command

  class << self
    # Travel to a specific location in the world
    #
    # Syntax: goto <entity id>
    #
    def goto(actor, arg)
      command_error 'Where would you like to go?' unless arg

      dest = get_component(arg, :location)&.entity
      dest ||= arg

      move_entity(entity: actor, dest: dest, look: true, ignore_limits: true)
    rescue Morrow::UnknownEntity
      command_error 'That does not exist in the world'
    end
  end
end
