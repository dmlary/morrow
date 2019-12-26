module Command
  class SyntaxError < ArgumentError; end

  class Definition
    def initialize(name, help, priority, wait, handler)
      @name = name
      @help = help
      @priority = priority.to_i
      @wait = wait
      @handler = handler
    end
    attr_reader :name, :priority, :handler, :wait
  end

  @lock = Mutex.new
  @commands = {}

  class << self
    # perform a command, as run by ++actor++
    def run(actor, buf)
      return if buf.nil? or buf.empty?
      name, rest = buf.split(/\s+/, 2)
      handler = lookup_handler(name) or return "unknown command: #{name}\n"
      handler.handler.call(actor, rest)

      # XXX handle waitstate adjustments
    end

    def lookup_handler(name)
      @commands[name] || begin
        pattern = /^#{Regexp.escape(name)}/
        @commands.values.select { |h| h.name =~ pattern }
            .sort_by { |h| h.priority }
            .last
      end
    end

    # register
    #
    # Register a command to be used by players.  Command handler may be
    # specified by the +block+ or the +method+ parameter.  The +wait+ parameter
    # defaults to 0, but System::CommandQueue limits command execution speed to
    # +World::PULSE+.
    #
    # Arguments:
    #   cmd: name of the command
    #   block: [optional] block-based command hander; see +method:+ parameter
    #
    # Parameters:
    #   method: Proc; command handler; alternative to &block
    #   priority: Integer; higher priority wins among commands with common
    #             prefixes
    #   wait: Float; wait-state implosed by running command
    #   help: String; help text
    #   
    def register(cmd, priority: 0, method: nil, wait: 0, help: nil, &block)
      @commands[cmd] = Definition.new(cmd, help, priority, wait, block || method)
    end
  end
end

require_relative 'command/look'
require_relative 'command/config'
require_relative 'command/movement'
require_relative 'command/act_obj'
require_relative 'command/act_wiz'
require_relative 'command/pretty_print'
