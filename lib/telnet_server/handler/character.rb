class TelnetServer::Handler::Character < TelnetServer::Handler::Base
  include World::Helpers

  def initialize(conn)
    # create our command queue
    @cmd_queue = Queue.new

    # Create a new player in the world (stick them in the void)
    @char = World.create_entity(base: 'base:player')
    World.get_component!(@char, :connection).conn = conn
    World.get_component!(@char, :command_queue).queue = @cmd_queue
    World.get_component!(@char, :player_config).color = true
    World.move_entity(entity: @char, dest: 'wbr:room/3001')
    World.remove_component(@char, ViewExemptComponent)

    # Add the 'look' command to the queue
    @cmd_queue.push('look')
  end

  def input_line(line)
    @cmd_queue.push(line)
    nil
  end

  def color?
    World.get_component!(@char, :player_config).color
  end
end
