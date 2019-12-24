require 'colorize'

class TelnetServer::Handler::Player < TelnetServer::Handler::Base
  def initialize(conn, char, world)
    super(conn)
    @char = char
    @world = world

    # close any existing link to the character
    if old_conn = char.conn
      send_line("Kicking off stale link")

      old_conn.send_line("Connected from another link; disconnecting")
      old_conn.close_connection(true)
    end

    # update the connection reference
    char.conn = conn

    # spawn the character if they don't already exist in the world
    char.transfer(world.room(1)) unless char.spawned?

    # XXX problem I'm having right now
    # World.pc's tracks all pc's in the world
    # World.room(1) tracks all chars inside it
    # char.room points at the room the char belongs to
    #
    # How do we keep this all in sync?
    #  - Need to ensure pc is added to world AND room at the same time
    #  - Trying to differentiate from World.spawn(npc, room), which will
    #    create a new instance of npc in the room
    #
    # sleepy brain now
    
    # Is the char already spawned?
    # spawn the char in the world

    # show news/motd

   
    

    # reconnect or
    # spawn the PC in the last room they were in, or in limbo
    


    # take a look around; throw up the prompt
    look
    prompt
  end

  def input_line(line)
    look
    prompt
  end

  def look
    room = @char.room
    send_line room.name.light_white
    send_line "   " + room.desc
    send_line "Terrain: %-10s  Exits: %s".light_white %
        [ room.terrain,
          room.exits.empty? ? 'none' : room.exits.join(', ') ]
    room.chars.each do |char|
      next if char == @char
      if char.standing?
        send_line char.long
      else
        send_line "#{char.name} is #{char.position} here"
      end
    end
    room.items.each { |i| send_line i.long }
  end

  def prompt
    send_line "" unless brief?
    "prompt> "
  end

  def brief?
    false
  end

  private
end
