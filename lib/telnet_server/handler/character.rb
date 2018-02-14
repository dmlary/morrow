class TelnetServer::Handler::Character < TelnetServer::Handler::Base
  def initialize(conn)
    # What is the difference between a tag and a class/module/constant?

    # Create a new entity in the world
    @char = Entity.new(:char)

    # stick it in the first room we can find
    room = World.by_type(:room).first
    @char << Component.new(:location, room.id)

    # Add the connection to the character
    @char << conn

    # set up a command queue, and add the look comman
    @char << @cmd_queue = CommandQueue.new
    @cmd_queue.push 'look'
  end
end
