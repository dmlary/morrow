class Morrow::TelnetServer::LoginHandler
  include Morrow::TelnetServer::InputHandler
  include Morrow::Helpers

  def initialize(conn)
    @char = spawn_at(dest: 'morrow:room/void', base: 'morrow:player')

    @conn = get_component!(@char, :connection)
    @conn.conn = conn

    @input = get_component!(@char, :input).queue = Thread::Queue.new

    @config = get_component!(@char, :player_config)
    @config.color = true

    update_char_resources(@char)
    input_line('look')

    remove_component(@char, :template)
  end

  def input_line(line)
    debug(recv: line)
    @conn.last_recv = Time.now
    @input.push(line)
    nil
  end

  def color?
    !!@config.color
  end
end
