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

    @components = {
      view_exempt: Morrow::ViewExemptComponent,
      keywords: Morrow::KeywordsComponent,
      container: Morrow::ContainerComponent,
      location: Morrow::LocationComponent,
      viewable: Morrow::ViewableComponent,
      animate: Morrow::AnimateComponent,
      corporeal: Morrow::CorporealComponent,
      concealed: Morrow::ConcealedComponent,
      exits: Morrow::ExitsComponent,
      environment: Morrow::EnvironmentComponent,
      destination: Morrow::DestinationComponent,
      player_config: Morrow::PlayerConfigComponent,
      metadata: Morrow::MetadataComponent,
      closable: Morrow::ClosableComponent,
      spawn_point: Morrow::SpawnPointComponent,
      spawn: Morrow::SpawnComponent,
      command_queue: Morrow::CommandQueueComponent,
      connection: Morrow::ConnectionComponent,
      teleporter: Morrow::TeleporterComponent,
      teleport: Morrow::TeleportComponent,
      affect: Morrow::AffectComponent,
    }

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
