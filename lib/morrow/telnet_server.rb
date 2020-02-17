require 'eventmachine'

module Morrow::TelnetServer
  class << self
    include Morrow::Logging

    attr_reader :connections, :world, :host, :port

    def start(host, port)
      @host = host
      @port = port
      @connections = []

      info "listening for connections on #{@host}:#{@port}"

      @server = EventMachine.start_server(@host, @port, Connection) do |conn|
        info "accepted connection from #{conn.host}:#{conn.port}"
        conn.server = self
        conn.push_handler(Morrow.config.telnet_login_handler)
        @connections.push(conn)
      end
    end
  end
end

require_relative 'telnet_server/connection'
require_relative 'telnet_server/input_handler'
require_relative 'telnet_server/login_handler'
