module Morrow::Command::CharPosition
  extend Morrow::Command

  class << self
    # Stand up
    #
    # Syntax: stand
    #
    def stand(actor, _)
      char = get_component(actor, :character) or
          fault("non-character entity: #{actor}")

      command_error('You are already standing.') if char.position == :standing

      char.position = :standing
      char.unconscious = false
      update_char_regen(actor)
      act('%{actor} %{v:stand} up.', actor: actor)
    end

    # Sit down
    #
    # Syntax: sit
    #
    def sit(actor, _)
      char = get_component(actor, :character) or
          fault("non-character entity: #{actor}")

      command_error('You are already sitting.') if char.position == :sitting

      dir = char.position == :lying ? 'up' : 'down'

      char.position = :sitting
      char.unconscious = false
      update_char_regen(actor)
      act('%{actor} %{v:sit} %{dir}.', actor: actor, dir: dir)
    end

    # Rest
    #
    # Syntax: rest
    #
    def rest(actor, _)
      char = get_component(actor, :character) or
          fault("non-character entity: #{actor}")

      command_error('You are already resting.') if
          char.position == :lying && char.unconscious == false

      wake = char.unconscious

      char.position = :lying
      char.unconscious = false
      update_char_regen(actor)

      act(wake ? '%{actor} %{v:wake} up.' : '%{actor} %{v:lay} down.',
          actor: actor)
    end

    # Sleep
    #
    # Syntax: sleep
    #
    def sleep(actor, _)
      char = get_component(actor, :character) or
          fault("non-character entity: #{actor}")

      command_error('You are already asleep.') if
          char.position == :lying && char.unconscious == true

      resting = char.position == :lying

      char.position = :lying
      char.unconscious = true
      update_char_regen(actor)

      act(resting ? '%{actor} %{v:fall} asleep.' : 
          '%{actor} %{v:lay} down and %{v:fall} asleep.',
          actor: actor, to_actor: true)
    end

    # Wake up
    #
    # Syntax: wake
    #
    def wake(actor, target)

      # handle the short path for just 'wake' of self
      unless target
        char = get_component(actor, :character) or
            fault("non-character entity: #{actor}")
        command_error('You are already awake.') unless char.unconscious
        char.unconscious = false
        update_char_regen(actor)
        act('%{actor} %{v:wake} up.', actor: actor)
        return
      end

      room = entity_location(actor) or fault("actor has no location: #{actor}")

      target = match_keyword(target, visible_chars(actor)) or
              command_error('You do not see them here.')

      char = get_component(target, :character) or
          command_error('You cannot wake that.')

      command_error('They are already awake.') unless char.unconscious

      if char.health < 1
        act('%{actor} %{v:try} to wake %{target}, but they are too hurt!',
            actor: actor, target: target)
        return
      end

      char.unconscious = false
      update_char_regen(target)
      act('%{actor} %{v:wake} %{target}.', actor: actor, target: target)
    end
  end
end
