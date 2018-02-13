require 'eventmachine'
require_relative 'helpers'

module TelnetServer
  class << self
    include Helpers::Logging

    attr_reader :connections, :world, :host, :port
    attr_reader :exceptions

    def start(host, port)
      @host = host
      @port = port
      @connections = []
      @exceptions = []

      info "listening for connections on #{@host}:#{@port}"

      @server = EventMachine.start_server(@host, @port, Connection) do |conn|
        info "accepted connection from #{conn.host}:#{conn.port}"
        conn.server = self
        # conn.push_input_handler(TelnetServer::Handler::Login.new(conn))
        conn.push_input_handler(TelnetServer::Handler::Character.new(conn))
        @connections.push(conn)
      end
    end
  end
end

require_relative 'telnet_server/connection'
require_relative 'telnet_server/handler'
require_relative 'telnet_server/handler/base'
require_relative 'telnet_server/handler/state_machine'
require_relative 'telnet_server/handler/login'
require_relative 'telnet_server/handler/new_char'
require_relative 'telnet_server/handler/player'
require_relative 'telnet_server/handler/character'
