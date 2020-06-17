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

  # ensure the actor is standing or raise a command error
  def standing!(actor, error = 'You must be standing to do this.')
    entity_position(actor) == :standing or command_error(error)
  end

  # ensure the actor is conscious or raise a command error
  def conscious!(actor,
                 error = 'You are currently unconscious and unable to act')
    entity_conscious?(actor) or command_error(error)
  end

  # ensure the actor is not incapacitated, or unable to act on their own
  def able!(actor, error = 'You are incapacitated and unable to act.')
    entity_health(actor) > 0 or command_error(error)
  end

  # ensure the actor is out of combat
  def out_of_combat!(actor, error = 'You cannot do that while in combat!')
    entity_in_combat?(actor) and command_error(error)
  end

  # ensure the actor is in combat
  def in_combat!(actor, error= 'You can only do that while in combat!')
    entity_in_combat?(actor) or command_error(error)
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
