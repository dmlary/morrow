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
  MSG_SUCCESS = 'You flee head over heels.'

  class << self
    # Attempt to escape from combat
    #
    # Syntax: flee
    #
    def flee(actor, _)
      in_combat!(actor, MSG_NOT_IN_COMBAT)
      conscious!(actor)
      standing!(actor, 'You must be standing to flee!')

      room = entity_location!(actor)
      exits = get_component(room, :exits) or command_error(MSG_NO_ESCAPE) 

      open_exits = Morrow::Helpers.exit_directions.select do |dir|
        next false unless exits[dir]
        next true unless door = exits["#{dir}_door"]
        entity_closed?(door) == false
      end

      command_error(MSG_NO_ESCAPE) if open_exits.empty?

      command_error(MSG_FAILED) if rand(100) < 15

      dir = open_exits.sample
      dest = exits[dir]

      move_entity(entity: actor, dest: dest, look: true)

      remove_component(actor, :combat)
      send_to_char(char: actor, buf: MSG_SUCCESS)
      act("&W%{actor} flees %{dir}!&0", in: room, actor: actor, dir: dir)
    rescue Morrow::EntityWillNotFit
      command_error(MSG_EXIT_FULL)
    end
  end
end
