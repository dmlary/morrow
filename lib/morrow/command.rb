require 'method_source'
require 'ostruct'

module Morrow::Command
  class Error < Morrow::Error; end

  class << self
    def extended(base)
      base.extend(Morrow::Helpers)
    end
  end

  # raises a Morrow::Command::Error, with the associated message to send to
  # the actor.
  def command_error(msg)
    raise Error, msg
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
