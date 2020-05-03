module Morrow::Command::Flee
  extend Morrow::Command

  # Message deplayed to the player when they try to flee when not in combat.
  MSG_NOT_IN_COMBAT = 'You are not in combat.'

  # Message displayed to a player when they are unable to flee because there
  # are no open exits from the room.
  MSG_NO_ESCAPE = '&RYou dart around, but all the exits are blocked!&0'

  # Message displayed to the player when they are able to flee from a room,
  # but fail to do so successfully.
  MSG_FAILED = "&RYou try to flee, but you could not escape!&0"

  # Message displayed to the player when they flee successfully, but the
  # desintation room is full.
  MSG_EXIT_FULL =
       "&RYou try to flee, but next room is too crowded for you to fit!&0"

  # Message displayed to the player when they successfully flee.
  MSG_SUCCESS = "MEEP"

  class << self
    # Attempt to escape from combat
    #
    # Syntax: flee
    #
    def flee(actor, _)
      room = entity_location(actor) or fault("actor has no location: #{actor}")

      if !entity_in_combat?(actor)
        send_to_char(char: actor, buf: MSG_NOT_IN_COMBAT)
        return
      end

      unless exits = get_component(room, :exits)
        send_to_char(char: actor, buf: MSG_NO_ESCAPE)
        return
      end

      open_exits= Morrow::Helpers.exit_directions.select do |dir|
        next false unless exits[dir]
        next true unless door = exits["#{dir}_door"]
        entity_closed?(door) == false
      end

      if open_exits.empty?
        send_to_char(char: actor, buf: MSG_NO_ESCAPE)
        return
      end

      if rand(100) < 15
        send_to_char(char: actor, buf: MSG_FAILED)
        return
      end

      dest = exits[open_exits.sample]
      move_entity(entity: actor, dest: dest, look: true)
      remove_component(actor, :combat)
      send_to_char(char: actor, buf: MSG_SUCCESS)
    rescue Morrow::EntityWillNotFit
      send_to_char(char: actor, buf: MSG_EXIT_FULL)
    end
  end
end
