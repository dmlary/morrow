module Command
  class SyntaxError < ArgumentError; end

  @lock = Mutex.new
  @commands = {}

  class << self
    # perform a command, as run by ++actor++
    def run(actor, buf)
      return if buf.nil? or buf.empty?
      name, rest = buf.split(/\s+/, 2)
      handler = lookup_handler(name) or return "unknown command: #{name}\n"
      handler.call(actor, rest)
    end

    def lookup_handler(name)
      @commands[name]
    end

    def register(cmd, method=nil, &handler)
      @commands[cmd] = block_given? ? handler : method
    end
  end
end

require_relative 'command/look'
require_relative 'command/config'
require_relative 'command/movement'
require_relative 'command/act_obj'
