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

  # Hash of playable classes in the game.  Key is class name, value is entity
  # that contains the class data.
  attr_accessor :classes

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

  # Character inventory maximum weight by strength table.  Default value is a
  # table where:
  # This table is used in `update_char_inventory_limits()`
  attr_accessor :char_inventory_max_weight

  # Character inventory maximum volume by dexterity table.  This table is used
  # in `update_char_inventory_limits()`.
  attr_accessor :char_inventory_max_volume

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

    # For determining the maximum weight a character can carry, I based it on
    # the weight of a full suit of plate armor, which google says weighs
    # 15 - 25 kg.  I wanted even characters with baseline strength 13 to be
    # able to carry that much, so baseline carry weight is 30kg.  Maximum carry
    # weight at 30 strength is 500kg (losely based off of world record for
    # squats).  Weak carry weight (at 8 strength) is 7kg, based off of stupid
    # airline weight limits for personal items.  Then, figure a carry weight of
    # 0 at 1 strength.
    #
    # I threw all of these points into wolfram alpha, plotted a curve, tossed
    # that into a spreadsheet to fill in the gaps, then simplified the numbers
    # by hand to create a smoothish/regular/round progression. 
    #
    # * 1 strength gives 0 kg max weight
    # * 8 strength (weak) gives 7 kg max weight
    # * 13 strength (normal) gives 30 kg max weight
    # * 30 strength (strongest) gives 500 kg max weight
    #
    # These numbers are grounded roughly based on:
    # * 7kg is a carry-on backpack for crappier airlines
    # * full set of plate armor is 15-25kg, average strength should be able to
    #   carry that
    # * world record for un-assisted squat is ~500kg
    #
    @char_inventory_max_weight = [
      0, 0, 1, 2, 3, 4, 5, 6, 7,    #  0 - 7    (severly weakened)
      10, 14, 19, 24, 30,           #  8 - 13   (weak to average)
      40, 50, 60, 75, 90,           # 14 - 18   
      110, 130, 150, 180, 210, 240, # 19 - 24
      280, 320, 360, 400, 450, 500, # 25 - 30   (very very strong)
    ]

    # Volume of inventory is strange.  We base it off of dexterity, as if it's
    # the number of items you could comfortably carry.  That's a little absurd
    # when you're carrying 100 potions just in your inventory.
    #
    # So we're going to try to establish a baseline for the average dex of 13.
    # A character with average/baseline dex of 13 should be able to carry:
    # * 6 liters of water, 2 liters per day, for 3 days
    # * 6 liters of food, 2 liters per day, for 3 days
    # * 0.150 liters of potions; 30 ml per potion, carry 5
    # * 10 liters for extra items/loot (equiped items don't count)
    #
    # This scale will probably need to be adjusted at some point.  It's all
    # just random numbers that get bigger.
    @char_inventory_max_volume = [
      0, 0, 1, 2, 4, 6, 8, 10, 12,  #  0 - 7    (severly clumsy)
      14, 16, 18, 20, 22,           #  8 - 13   (weak to average)
      25, 30, 35, 40, 45,           # 14 - 18   
      50, 60, 70, 80, 90, 100,      # 19 - 24
      110, 120, 130, 140, 150, 160, # 25 - 30   (very very dex)
    ]

    @components = {
      abilities: Morrow::Component::Abilities,
      affect: Morrow::Component::Affect,
      character: Morrow::Component::Character,
      class_definition: Morrow::Component::ClassDefinition,
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

    @classes = {
      warrior: 'morrow:class/warrior'
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
