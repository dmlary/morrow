class Morrow::TelnetServer::LoginHandler
  include Morrow::TelnetServer::InputHandler
  include Morrow::Helpers

  def initialize(conn)
    @input = Thread::Queue.new

    @char = create_entity(base: 'morrow:player')
    @conn_comp = get_component!(@char, :connection)
    @conn_comp.conn = conn
    @conn_comp.last_recv = now
    @conn_comp.buf = ''
    get_component!(@char, :input).queue = @input
    @config = get_component!(@char, :player_config)
    @config.color = true
    move_entity(entity: @char, dest: 'morrow:room/void')
    remove_component(@char, :view_exempt)

    @input.push('look')
  end

  def input_line(line)
    @input.push(line)
    nil
  end

  def color?
    !!@config.color
  end
end
