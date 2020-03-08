module Morrow::Command::Look
  extend Morrow::Command

  class << self
    # Attack another character
    #
    # Syntax: kill <character>
    #
    def kill(actor, target)
      command_error 'What would you like to attack?' unless target

      room = entity_location(actor) or fault("actor has no location: #{actor}")
      target = match_keyword(target, visible_chars(actor)) or
              command_error 'You do not see that here.'

      hit_entity(actor: actor, entity: target)
    end
    alias hit kill
  end
end
