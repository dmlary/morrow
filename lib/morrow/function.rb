require 'forwardable'
require 'parser/current'
require 'yaml'

# Turn on some things for the parser
Parser::Builders::Default.emit_lambda   = true
Parser::Builders::Default.emit_index    = true

# Class for parsing & running mathematical functions written in ruby.  This is
# a stricter implementation than the Script class.  See Script class for
# description of the security model implemented here.
#
# Examples:
#
#   # linear function
#   f = Function.new('{ |l| l * 12 }')
#   f.call(10) # => 120
#
#   # function with exponentiation
#   f = Function.new('{ |l| 2 * (l ** 1.1) }')
#   f.call(5) # => 11.746189430880191
#
#   # simple conditional function
#   f = Function.new('{ |l| l > 50 ? l * 1.5 : l }')
#   f.call(50)  # =>  50
#   f.call(51)  # =>  76.5
#
#   # case-based conditional function
#   f = Function.new(<~FUNC)
#     do |arg|
#       case arg
#       when 0..10
#         arg * 2
#       else
#         arg * 3
#       end
#     end
#   FUNC
#   f.call(4)   # =>  8
#   f.call(11)  # =>  33
#
class Morrow::Function
  # NodeTypeWhitelist
  #
  # This is the list of Parser::AST::Node types that are permitted within the
  # function source code.  From the test cases (see rspec), this is the minimum
  # subset needed to provide a robust language for functions.
  #
  #                           *** IMPORTANT ***
  # Have a good reason to modify this list, and verify that all the tests pass
  # before releasing changes.  This limited subset of functionality provides
  # half the security for functions.
  #                           *** IMPORTANT ***
  #
  NodeTypeWhitelist = %i{ block int float irange erange begin if case when or
                          and lvar lvasgn op_asgn and_asgn or_asgn next hash
                          pair sym }

  # InstanceMethodWhitelist
  #
  # This is the list of methods a function may call on **any** instance it has
  # access to.  This list must be kept as small as possible to reduce the
  # attack surface.
  #
  # Before you add anything to this list:
  #   * Be absolutely certain it is needed
  #   * Verify that the added method does not have unintended side-effects on
  #     other instances
  #     * Look at the added method for each of the base types permitted:
  #       * Array, Hash, String, Integer, Float, Symbol, Range, true, false,
  #         and nil
  #       * Make sure none of them provide access to `eval` or `send`
  #       * Make sure none of them allow Strings to be converted to code
  #     * Look at **EVERY** type returned from every method in function::Sandbox
  #       for the same things
  #       * Note that most methods are pulled from World::functionSafeHelpers
  #   * After doing all of that, be certain you actually need the function
  #
  # DO NOT MODIFY this list if you're not comfortable stating that your change
  # **cannot** be used to remotely execute code on the server.
  InstanceMethodWhitelist = %i{ + - / * ** ! > >= < <= }

  # ProhibitedFunctionElementError
  #
  # Parent class for exceptions we raise when a function is determined to be
  # unsafe.  This is mostly helper functions for the specific exceptions we
  # encounter.
  class ProhibitedFunctionElementError < Morrow::Error
    def initialize(error, error_node)
      @error = error
      @error_node = error_node

      line = error_node.loc.line
      column = error_node.loc.column + 1
      msg = "At line #{line}, column #{column}, #{error}\n"
      msg << clang_error

      super(msg)
    end

    # clang_error
    #
    # Generate a clang formatted error for this exception
    def clang_error
      loc = @error_node.loc
      expr = loc.expression
      line = loc.line
      column = loc.column + 1
      prefix = "#{expr.source_buffer.name}:#{line}:"
      out = "#{prefix}#{column}: error: #{@error}\n"
      out << "#{prefix} #{expr.source_line}\n"
      out << "#{prefix} "
      out << ' ' * (column - 1)
      out << "^\n"
    end
  end
  class ProhibitedMethod < ProhibitedFunctionElementError;
    def initialize(method, error_node)
      super("prohibitied method call, #{method}.", error_node)
    end
  end
  class ProhibitedNodeType < ProhibitedFunctionElementError;
    def initialize(type, error_node)
      super("prohibitied ruby code, #{type}.", error_node)
    end
  end
  class UnexpectedNode < ProhibitedFunctionElementError;
    def initialize(expected, error_node)
      super("unexpected ruby code; expected #{expected}.", error_node)
    end
  end

  # initialize
  #
  # Create a new function with the source provided
  #
  # Arguments:
  #   source: function source
  #
  # Parameters:
  #   freeze: set to false to not freeze the class; ONLY FOR TESTING
  #
  def initialize(source)
    @source = source.clone.freeze
    safe!
  end

  # Make yaml create a function instance for `!function` tags
  YAML.add_tag '!func', self

  # initializer when loaded from yaml
  def init_with(coder)
    raise Morrow::Error, "invalid function: %s " %
        [ coder.send(coder.type).inspect ] unless coder.type == :scalar
    @source = coder.scalar.to_s.freeze
    safe!
  end

  # encode the Function to yaml
  def encode_with(coder)
    coder.scalar = @source
  end

  # call
  #
  # Call the function with provided arguments.
  def call(entity: nil, component: nil, field: nil, level: nil)
    raise Morrow::Error, "refusing to run unsafe function: #{self}" unless @proc

    sandbox = Sandbox.new(entity: entity, component: component, field: field,
                          level: level)
    sandbox.instance_eval(&@proc)
  end

  # to_s
  #
  # simplest approach is to give the yaml
  def to_s
    @source
  end

=begin
  func = get_component('morrow:class:warrior', :character).health_func
  func.call(entity: char, level: war_level)
  eval_func(entity: 'morrow:class/warrior',
      component: :character, field: :health_func, level: war_level)

  entity_components(entity) do |comp|
    comp.each do |field, value|
      next unless value.is_a?(Morrow::Function)
      comp[field] = value.eval(entity: entity, comp: comp, field: field)
    end
  end
=end
  private

  # safe!
  #
  # Check to see if the function source is safe to be run
  def safe!
    begin
      buf = 'proc %s' % @source
      root = parse(buf)
      raise UnexpectedNode.new('block', root) unless root.type == :block

      p, args, body = root.children
      raise UnexpectedNode.new('proc()', p) unless
          p.type == :send && p.children == [ nil, :proc ]
      raise UnexpectedNode.new('args', args) unless
          args.type == :args
      node_safe!(body)

      @proc = eval(buf)
    ensure
      # After verifying the function is safe, we freeze the instance so that it
      # cannot easily be modified later to run unsafe code.
      self.freeze
    end
  end

  # parse
  #
  # Wrapper around Parser::Current#parse() to silence the stderr output on
  # syntax errors.  Opened https://github.com/whitequark/parser/issues/644
  # but they didn't feel it was necessary to add that option to the top-level.
  #
  # Arguments: None
  #
  # Returns: Parser::AST::Node
  def parse(source)
    parser = Parser::CurrentRuby.new
    parser.diagnostics.all_errors_are_fatal = true
    parser.diagnostics.ignore_warnings      = true
    source_buffer = Parser::Source::Buffer.new('function')
    source_buffer.source = source
    parser.parse(source_buffer)
  end

  # node_safe!
  #
  # Verify that a Parser::AST::Node is in our whitelist.  If it is not, raise
  # an exception noting why the node is considered unsafe.
  def node_safe!(node, lvars: {})
    return unless node.is_a?(Parser::AST::Node)

    case node.type
    when :send

      # This is a call to a method.  If there's a receiver, we'll use the
      # instance method whitelist, otherwise we'll use the list of functionable
      # methods from the sandbox.
      receiver, method = node.children
      whitelist = receiver ? InstanceMethodWhitelist :
          Sandbox.instance_methods(false)
      raise ProhibitedMethod.new(method, node) unless
          whitelist.include?(method)
    else

      # If the node type is not supported, raise an exception.
      raise ProhibitedNodeType.new(node.type, node) unless
          NodeTypeWhitelist.include?(node.type)
    end
    node.children.each { |c| node_safe!(c) }
  end
end

require_relative 'function/sandbox'
