require 'forwardable'
require 'parser/current'

# Turn on some things for the parser
Parser::Builders::Default.emit_lambda   = true
Parser::Builders::Default.emit_index    = true

# Script
#
# module for securely running scripts
#
# This class takes ruby code, verifies that it falls within the subset of what
# we deem as safe code, and runs it.
#
# We take an explicit whitelist approach to all of the code in the script.
# Starting with parsing the ruby code into an AST, we only allow the following:
#   * use of basic datatypes:
#     * Integer, Float, String, Array, Hash, Symbol, Range
#   * assignment to local variables
#   * flow control (if/elsif/else, unless, while, case, until)
#   * logical conditions (or, and, and not)
#   * white-list based method calls
#
# Some things that are not permitted:
#   * accessing any Constant
#   * defining classes, modules, methods
#
# There are three whitelists that dictate what the script can run.  You can
# read more about each one at their definitions.
#   NodeTypeWhitelist: Parser::AST::Node types that are permitted in the source
#   InstanceMethodWhitelist: methods that may be called on instances
#   Sandbox::ScriptMethods: any other methods that may be called (no instance)
#
class Script
  # NodeTypeWhitelist
  #
  # This is the list of Parser::AST::Node types that are permitted within the
  # script source code.  From the test cases (see rspec), this is the minimum
  # subset needed to provide a functional scripting facility.
  #
  #                           *** IMPORTANT ***
  # Have a good reason to modify this list, and verify that all the tests pass
  # before releasing changes.  This limited subset of functionality provides
  # half the security for scripts.
  #                           *** IMPORTANT ***
  #
  NodeTypeWhitelist = %i{
      nil true false sym int float str array hash pair dstr
      lvasgn indexasgn masgn mlhs op_asgn and_asgn or_asgn
      if case when while until irange erange begin
      next break return block args arg or and not
      lvar index
  }

  # InstanceMethodWhitelist
  #
  # This is the list of methods a script may call on **any** instance it has
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
  #     * Look at **EVERY** type returned from every method in Script::Sandbox
  #       for the same things
  #       * Note that most methods are pulled from World::ScriptSafeHelpers
  #   * After doing all of that, be certain you actually need the function
  #
  # DO NOT MODIFY this list if you're not comfortable stating that your change
  # **cannot** be used to remotely execute code on the server.
  InstanceMethodWhitelist = %i{
    ! % & | ^ + - * / == =~ === < > <= >= << >> [] []=
    first each map inject nil?
  }

  # UnsafeScript
  #
  # Exception we raise for untrusted elements in the script
  class UnsafeScript < RuntimeError
    attr_reader :root, :node

    def initialize(msg, root, node)
      @root = root
      @node = node
      super(msg)
    end
  end

  # initialize
  #
  # Create a new script with the source provided
  def initialize(script)
    @source = script.clone.freeze
  end

  # Make yaml create a Script instance for `!script` tags
  YAML.add_tag '!script', self

  # initializer when loaded from yaml
  def init_with(coder)
    raise RuntimeError, "invalid script: %s " %
        [ coder.send(coder.type).inspect ] unless coder.type == :scalar
    @source = coder.scalar.to_s.freeze
    safe!
  end

  # encode the Script to yaml
  def encode_with(coder)
    coder.scalar = @source
  end

  # safe!
  #
  # Check to see if the script source is safe to be run
  def safe!
    ast = Parser::CurrentRuby.parse(@source)
    node_safe!(ast)
    true
  end

  # call
  #
  # Call the script with provided arguments.
  def call(entity: nil, actor: nil)
    # XXX for the moment, we'll verify each time.  Later let's clean this up
    # and only verify safe once, cache the result, and freeze the class.
    safe!

    # eval the code within the Sandbox, but first set the entity & actor
    # provided.
    Sandbox.instance_exec(@source) do |source|
      entity = entity
      actor = actor
      eval(source)
    end
  end

  private

  # node_safe!
  #
  # Verify that a Parser::AST::Node is in our whitelist.  If it is not, raise
  # an exception noting why the node is considered unsafe.
  def node_safe!(node, lvars: {})
    return unless node.is_a?(Parser::AST::Node)

    case node.type
    when :send

      # This is a call to a method.  If there's a receiver, we'll use the
      # instance method whitelist, otherwise we'll use the list of scriptable
      # methods from the sandbox.
      receiver, method = node.children
      whitelist = receiver ? InstanceMethodWhitelist : Sandbox::ScriptMethods
      raise UnsafeScript
          .new("method not permitted: #{method} in #{node}", @ast, node) unless
              whitelist.include?(method)

    else

      # If the node type is not supported, raise an exception.
      raise UnsafeScript
          .new("node type not in whitelist: #{node.type}", @ast, node) unless
          NodeTypeWhitelist.include?(node.type)
    end
    node.children.each { |c| node_safe!(c) }
  end
end

require_relative 'script/sandbox'
