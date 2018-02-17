require 'pry'
require 'pp'
require 'colorize'

module ExceptionBinding
  @events = []
  @stack = Hash.new { |h,k| h[k] = [] }
  @trace = TracePoint.new(:line, :call, :return, :b_call, :b_return) do |tp|
      stack = @stack[Thread.current]

      case tp.event
      when :return, :b_return
        stack.pop
      when :call, :b_call
        stack.push [ tp.method_id, tp.path, tp.lineno, tp.defined_class,
                     tp.binding]
      when :line
        element = [ tp.method_id, tp.path, tp.lineno, tp.defined_class,
                    tp.binding ]
        stack.empty? ? stack[0] = element : stack[-1] = element
      end
    end

  class << self
    # Maximum number of events we save
    EVENTS_MAX = 10
    attr_reader :events

    def enabled?
      @trace.enabled?
    end

    def enable
      @stack.clear
      @trace.enable
      nil
    end

    def disable
      @trace.disable
      @stack.clear
      nil
    end

    def enabled=(value)
      if value
        enable unless enabled?
      else
        disable
      end
    end

    def stack
      @stack[Thread.current].clone if @trace.enabled?
    end

    def pry_when(&block)
      @pry_check = block
    end

    def pry?(exception)
      # Clear the pry_check method if it is the source of the exception
      @pry_check = nil if exception.stack.frames
          .find { |f| f.klass == self.singleton_class and f.method == :pry? }

      @pry_check ? @pry_check.call(exception) : false
    end

    def add_event(ex)
      @events.shift if @events.size > EVENTS_MAX
      @events.push(ex)
    end
  end

  module ExceptionMethods
    attr_reader :stack

    # XXX this may not be called when an exception is raised from c.  Currently
    # doesn't happen when we call a method with the wrong number of arguments
    def set_backtrace(backtrace)
      super
      set_stack
    end

    def initialize(*args)
      super
      set_stack unless @stack
    end

    private

    def set_stack
      stack = ExceptionBinding.stack or return

      # our stack will include at least these three:
      #   [:set_backtrace, :set_stack, :stack ]
      # trim them off the stack
      stack.pop(3)

      # We also want to pop off the frame for initialize
      method, file, klass = stack.last
      stack.pop if method == :initialize and
          file == __FILE__ and
          klass == ExceptionBinding::ExceptionMethods

      # Pull the stack up to the first call to #set_backtrace
      @stack = Stack.new(self, stack)

      # add this to the global list of exceptions captured
      ExceptionBinding.add_event(self)

      # try not to recursively get stuck in pry
      return if @stack.in_pry?

      return unless frame = ExceptionBinding.pry?(self)
      @stack.pry(frame)
    end
  end

  class Stack
    class Frame
      def initialize(method, file, line, klass, binding)
        @method = method
        @file = file
        @line = line
        @klass = klass
        @binding = binding
      end
      attr_reader :method, :file, :line, :klass, :binding
    end

    def initialize(ex, frames)
      @ex = ex
      @frames = frames.map { |f| Frame.new(*f) }
      @pos = frames.size - 1
    end
    attr_reader :ex, :frames, :pos

    # return the binding for the current stack frame
    def frame_binding
      @frames[pos].binding
    end

    # return the last/highest frame in the stack
    def last_frame
      @frames.last
    end

    # Update the current stack frame
    def pos=(pos)
      pos = 0 if pos < 0
      pos = @frames.size - 1 if pos >= @frames.size
      @pos = pos
    end

    # check if the supplied binding is a part of this stack
    def include?(binding)
      !!@frames.find { |f| f.binding == binding }
    end

    # start up pry within this stack
    def pry(frame=nil)
      @pos = frames.find_index { |f| f == frame } || @frames.size - 1
      frame_binding.pry(exception: @ex, stack: self)
    end

    # check to see if this stack is running in pry
    def in_pry?
      !!@frames.find { |f| [Pry.singleton_class, Pry::Command, Pry::REPL].include? f.klass }
    end

    def to_s
      # header
      buf = "\nstacktrace:\n".bold.white

      # loop through our stack entries
      @frames.each_with_index.reverse_each do |frame,i|
        meth = frame.method
        file = frame.file
        line = frame.line
        klass = frame.klass
        binding = frame.binding

        # construct the index and location name
        index = "%2d".colorize(color: :white, mode: :bold) % i
        location = if meth.nil?
          "#{file}:#{line}"
        elsif klass.nil?
          "##{meth}    #{file}:#{line}"
        elsif klass.methods.include?(meth)
          "#{klass.to_s.colorize(color: :blue, mode: :bold)}.#{meth}"
        else
          "#{klass.to_s.colorize(color: :blue, mode: :bold)}##{meth}"
        end

        # output the line
        buf << "  %s [%s] #{location}\n" %
            [ self.pos == i ? "=>" : "  ", index ]
      end
      buf
    end
  end
end

class Exception
  prepend ExceptionBinding::ExceptionMethods
end

# Add support for the following parameters
#
# ++:exception++ set the last_exception to this value
# ++:stack++ set the stack for use with stack-up/down
#
Pry.hooks.delete_hook(:when_started, :set_exception)
Pry.hooks.add_hook(:when_started, :set_exception) do |b,opt,_pry_|
  _pry_.last_exception = opt[:exception] if opt[:exception].is_a?(Exception)
  next unless stack = opt[:stack]
  _pry_.extra_sticky_locals[:stack] = stack
#  _pry_.binding_stack = [stack.frame_binding]
end

# Patch up 'whereami' to include the stack trace at the top if we're in the
# stack
# Pry.config.commands
#     .find_command_by_match_or_listing('whereami')
#     .hooks[:before]
#     .delete_if { |h| h.source_location == __FILE__ }
Pry.config.commands.before_command('whereami') do |num|
  stack = _pry_.extra_sticky_locals[:stack] or next
  context = _pry_.current_context
  next if context and !stack.include?(context)
  output.puts stack.to_s
end

# Add stack-up command
begin
  Pry::Commands.delete('stack-up')
rescue
end
Pry::Commands.create_command('stack-up') do
  description 'move to a higher frame on the stack'

  def process
    stack = _pry_.extra_sticky_locals[:stack] or
        raise ArgumentError, 'no stack'
    raise ArgumentError, 'current context not in stack' unless
        stack.include?(_pry_.current_context)

    stack.pos -= (args.empty? ? 1 : args.first.to_i)
    _pry_.binding_stack[-1] = stack.frame_binding
    _pry_.run_command('whereami')
  end
end

# Add stack-down command
begin
  Pry::Commands.delete('stack-down')
rescue
end
Pry::Commands.create_command('stack-down') do
  description 'move to a lower frame on the stack'

  def process
    stack = _pry_.extra_sticky_locals[:stack] or
        raise ArgumentError, 'no active stack'
    raise ArgumentError, 'current context not in stack' unless
        stack.include?(_pry_.current_context)

    stack.pos += (args.empty? ? 1 : args.first.to_i)
    _pry_.binding_stack[-1] = stack.frame_binding
    _pry_.run_command('whereami')
  end
end
