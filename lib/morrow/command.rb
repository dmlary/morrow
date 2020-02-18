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

  # Create a help document for the following command.
  def help(keywords, body)
    keywords = [ keywords ] unless keywords.is_a?(Array)
    keywords.map! { |w| w.to_s.downcase }
    keywords.unshift('command') unless keywords.include?('command')
    @help = { keywords: keywords, body: body.chomp }
  end

  # Define the priority of the following command.  When two commands match the
  # same substring ('s' matching 'spawn' and 'south'), the command with the
  # higher priority will be executed.
  def priority(priority)
    @priority = priority.to_i
  end

  # Any public singleton methods added to a module that extends this module
  # will automatically be added to the command list for Morrow.
  def singleton_method_added(name)

    # Only add public methods to the commands list
    return unless public_methods.include?(name)

    handler = method(name)
    name = name.to_s

    Morrow.config.commands[name] =
        OpenStruct.new(name: name,
            priority: @priority || 0,
            handler: handler,
            help: @help)

    @help = nil
    @priority = nil
  end
end
