require 'logger'

# Configuration for Morrow
#
#   Morrow.run do |config|
#     config.host = '0.0.0.0'       # bind to all ip's on the host
#     config.host = 'localhost'     # Only bind to localhost
#     config.host = 'morrow.local'  # only bind to morrow.local
#     config.telnet_port = 1234     # listen for telnet on 1234
#
#     # Set up a custom login handler
#     config.telnet_login_handler = CustomLoginHandler
#
#     # Serve a custom web-interface that uses the webserver backend
#     config.public_html = './public_html'
#   end
class Morrow::Configuration

  # Environment to run the server in; :development, :test, or :production
  attr_accessor :env

  # Logger instance to write all logs to
  attr_accessor :logger

  # Hostname or IP address to bind the servers to
  attr_accessor :host

  # Port number to listen for telnet connections; nil disables telnet
  attr_accessor :telnet_port

  # Morrow::TelnetServer::InputHandler to handle initial greeting & login
  attr_accessor :telnet_login_handler

  # Port number to listen for http connections; nil disables http
  attr_accessor :http_port

  # Directory to serve static web content from.  Use this to replace the web
  # interface.
  attr_accessor :public_html

  # Map of Component name to Component class for all Components in use in the
  # world.
  attr_accessor :components

  def initialize
    @env = ENV['APP_ENV']&.to_sym || :development
    @host = development? ? 'localhost' : '0.0.0.0'
    @http_port = 8080
    @logger ||= Logger.new(STDERR)

    @telnet_port = 5000
    @telnet_login_handler = Morrow::TelnetServer::LoginHandler

    @public_html = File.join(File.dirname(__FILE__), '../../dist')

    @components = {}
  end

  def development?
    @env == :development
  end

  def production?
    @env == :production
  end

  def test?
    @env == :test
  end
end
