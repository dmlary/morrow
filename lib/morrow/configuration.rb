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

  # Hash of Component name to Component class for all Components in use in the
  # world.
  #
  #   Morrow.config.components[:resources] = MyResourceComponent
  #   Morrow.config.components[:shadow] = ShadowComponent
  attr_accessor :components

  # Array of System modules that should be run each Morrow.update().  Ensure
  # that the last system in this array is the connection handler.
  attr_accessor :systems

  # Hash of command name to Command definitions.  All commands that are defined
  # in the world appear in this Hash.
  attr_accessor :commands

  # Directory that contains runtime data for Morrow.  Used as the default
  # prefix for world_dir and player_dir
  attr_accessor :data_dir

  # Directory that contains the entity files to load into the world.
  # Default: File.join(data_dir, 'world')
  attr_writer :world_dir

  # When set to false, the base entities included with Morrow will not be
  # loaded.  Default: true
  attr_accessor :load_morrow_base

  # Time, in seconds, before an idle connection is disconnected.  Default: 15
  # minutes
  attr_accessor :disconnect_timeout

  # Update frequency in seconds; default 0.25
  attr_accessor :update_interval

  def initialize

    @env = ENV['APP_ENV']&.to_sym || :development
    @host = development? ? 'localhost' : '0.0.0.0'
    @http_port = 8080
    @logger ||= Logger.new(STDERR)

    @telnet_port = 5000
    @telnet_login_handler = Morrow::TelnetServer::LoginHandler

    base_dir = File.expand_path('../../../', __FILE__)
    @public_html = File.join(base_dir, 'dist')
    @data_dir = File.join(base_dir, 'data')
    @world_dir = nil    #
    @load_morrow_base = true

    @disconnect_timeout = 15 * 60

    @update_interval = 0.25

    @components = {
      abilities: Morrow::Component::Abilities,
      affect: Morrow::Component::Affect,
      animate: Morrow::Component::Animate,
      closable: Morrow::Component::Closable,
      combat: Morrow::Component::Combat,
      concealed: Morrow::Component::Concealed,
      connection: Morrow::Component::Connection,
      container: Morrow::Component::Container,
      corporeal: Morrow::Component::Corporeal,
      decay: Morrow::Component::Decay,
      environment: Morrow::Component::Environment,
      exits: Morrow::Component::Exits,
      help: Morrow::Component::Help,
      input: Morrow::Component::Input,
      keywords: Morrow::Component::Keywords,
      location: Morrow::Component::Location,
      metadata: Morrow::Component::Metadata,
      player_config: Morrow::Component::PlayerConfig,
      resources: Morrow::Component::Resources,
      spawn: Morrow::Component::Spawn,
      spawn_point: Morrow::Component::SpawnPoint,
      teleport: Morrow::Component::Teleport,
      teleporter: Morrow::Component::Teleporter,
      template: Morrow::Component::Template,
      viewable: Morrow::Component::Viewable,
    }

    @systems = [
      Morrow::System::Spawner,
      Morrow::System::Input,
      Morrow::System::Teleport,
      Morrow::System::Combat,
      Morrow::System::Decay,
      Morrow::System::Connection,
      Morrow::System::Regen,
    ]

    # Note: this hash is populated dynamically by modules that extend the
    # Command module.
    @commands = {}
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

  def world_dir
    @world_dir || File.join(@data_dir, 'world')
  end
end
