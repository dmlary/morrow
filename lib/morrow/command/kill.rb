module Morrow::Command::Kill
  extend Morrow::Command

  class << self
    # Attack another character
    #
    # Syntax: kill <character>
    #
    def kill(actor, target)
      able!(actor)
      out_of_combat!(actor, 'You are already engaged in combat.')
      standing!(actor, 'You must be standing to attack.')

      command_error 'What would you like to attack?' unless target

      room = entity_location(actor) or fault("actor has no location: #{actor}")
      target = match_keyword(target, visible_chars(actor)) or
              command_error 'You do not see them here.'

      if target == actor
        send_to_char(char: actor, buf: 'You take a swing at yourself and miss.')
        return
      end

      hit_entity(actor: actor, entity: target)
    end
    alias hit kill
  end
end
