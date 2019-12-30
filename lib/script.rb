require 'forwardable'
require 'parser/current'
# opt-in to most recent AST format:
Parser::Builders::Default.emit_lambda   = true
Parser::Builders::Default.emit_index    = true

# Script
#
# module for parsing world scripts
class Script
  class UnsafeScript < RuntimeError
    def initialize(msg, root, node)
      @root = root
      @node = node
      super(msg)
    end
  end

  # Sandbox
  #
  # Sandbox in which scripts get evaluated.  All methods in the ScriptMethods
  # array are available for the script to use.
  module Sandbox
    # variable names used when calling scripts; we fake like they are methods
    # so that the safe-check knows they are permitted.
    ScriptMethods = [ :entity, :actor ]

    # pull in logging methods
    extend Helpers::Logging
    ScriptMethods.push(*::Helpers::Logging.public_instance_methods(false))
    ScriptMethods.delete(:logger)   # they won't need to poke at logger

    # explicitly pull in World::Helpers
    extend ::World::Helpers
    ScriptMethods.push(*::World::Helpers.public_instance_methods(false))

    # Add other functionality from outside of the Sandbox in
    class << self
      extend Forwardable
      def_delegators :Time, :now
      def_delegators :Kernel, :rand
    end
    ScriptMethods.push(*singleton_class.public_instance_methods(false))
  end

  def initialize(script)
    @script = script
  end
  attr_reader :ast

  def safe!
    @ast ||= Parser::CurrentRuby.parse(@script)
    node_safe!(@ast)
  end

  # Based on our test-cases, these are the minimum nodes we need to permit in
  # the AST.
  #
  # *** IMPORTANT ***
  # Have a DAMN good reason to modify this list, and verify that all the tests
  # pass before releasing changes.  This limited subset of functionality
  # provides half the security for scripts.
  #
  # *** IMPORTANT ***
  NodeTypeWhitelist = %i{
      nil true false sym int float str array hash pair
      lvasgn indexasgn masgn mlhs op_asgn and_asgn or_asgn
      if case when while until irange erange begin
      next break return block args arg or and
      lvar index
  }

  # node_safe!
  #
  # Verify that a Parser::AST::Node is in our whitelist.  If it is not, raise
  # an exception noting why the node is considered unsafe.
  def node_safe!(node, lvars: {})
    return unless node.is_a?(Parser::AST::Node)

    case node.type
    when :send
      receiver, method = node.children
      whitelist = receiver ? ReceiverMethodWhitelist : Sandbox::ScriptMethods

      raise UnsafeScript
          .new("method not permitted: #{method} in #{node}", @ast, node) unless
              whitelist.include?(method)
    else
      raise UnsafeScript
          .new("node type not in whitelist: #{node.type}", @ast, node) unless
          NodeTypeWhitelist.include?(node.type)
    end
    node.children.each { |c| node_safe!(c) }
  end

  # Be VERY careful adding methods to this list.  If any type the script has
  # access to implements these in a way that the caller can get access to
  # `eval` or a generic Class or Module, security will be compromised.
  #
  # This list was generated from:
  #   types = [ [], {}, '', 1, :Sym, true, false, nil, 1..1 ]
  #   methods = types.map { |t| t.public_methods(false) }.flatten.sort.uniq
  #
  # Then going through the methods and manually verifying they do grant the
  # script any additional access.  Someone else should review this.
  ReceiverMethodWhitelist = %i{
    ! % & | ^ + - * / == =~ === < > <= >= << >> [] []= first each map inject
    nil?
  }

  # did this by hand, but fuuuuck that; let's do it each one as needed
  %i{
    % & * ** + +@ - -@ / < << <= <=> == === =~ > >= >> [] []= ^ abs all? any?
    append at capitalize capitalize! ceil chomp chomp! chop chop! clear
    collect collect! combination compact compact! count cycle delete delete!
    delete_at delete_if downcase downcase! drop drop_while each each_char
    each_index each_key each_line each_pair each_value empty? entries eql?
    even? filter filter! find_index first flatten flatten! floor freeze gsub
    gsub! has_key? has_value? include? indent indent! index insert inspect
    join keep_if key key? keys last length lines ljust lstrip lstrip! map
    map! match match? max member? merge merge! min modulo next next! nil?
    none? odd? one? pop prepend push reject reject! replace reverse
    reverse! reverse_each rindex rjust rotate rotate! round rstrip rstrip!
    sample scan select select! shift shuffle shuffle! size slice slice! sort
    sort! sort_by! split squeeze squeeze! step strip strip! sub sub! sum
    take take_while times to_a to_ary to_f to_h to_hash to_i to_int to_s to_str
    to_sym truncate union uniq uniq! unshift upcase upcase! upto value?
    values values_at zip
  }
end
