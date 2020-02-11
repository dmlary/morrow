require 'method_source'
require 'ostruct'

module Morrow::Command
  class SyntaxError < Morrow::Error; end

  def self.extended(base)
    base.extend(Morrow::Helpers)
  end

  # Any public singleton methods added to a module that extends this module
  # will automatically be added to the command list for Morrow.
  def singleton_method_added(name)

    # Only add public methods to the commands list
    return unless public_methods.include?(name)

    handler = method(name)
    help = handler.comment
    name = name.to_s

    Morrow.config.commands[name] =
        OpenStruct.new(name: name, priority: 0, help: help, handler: handler)
  end
end
