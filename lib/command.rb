module Command
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

    def register(cmd, &handler)
      @commands[cmd] = handler
    end
  end
end

require_relative 'command/look'
