# Morrow::Script::Sandbox
#
# Sandbox in which scripts get evaluated.  All methods in the ScriptMethods
# array are available for the script to use.
module Morrow::Script::Sandbox

  # ScriptMethods
  #
  # This is the list of methods the script is allowed to call in the sandbox.
  # There is a second list of instance methods the script may call in
  # Script::InstanceMethodWhitelist.
  #
  # Be **extremely** careful about what methods you add to the sandbox.
  # Methods you add **may** be used to remotely exploit the server.
  # DO NOT MODIFY this sandbox if you do not understand how a new method could
  # result in security compromise.
  #
  # If you do modify this, be sure you run the test cases before committing.
  # There are some generic tests in there to detect blatantly bad additions,
  # BUT IN NO WAY IS IT COMPLETE.
  #
  # First things in this list are actually variables we get when the script is
  # run.  We act like they're methods so that Script#safe! doesn't think
  # they're unauthorized methods.
  ScriptMethods = [ :args, :config, :raise ]

  # Pull in the standard logging functions
  extend Morrow::Logging
  ScriptMethods.push(*Morrow::Logging.public_instance_methods(false))

  # explicitly pull in scriptable helpers
  extend Morrow::Helpers::Scriptable
  ScriptMethods
      .push(*Morrow::Helpers::Scriptable.public_instance_methods(false))

  # Scripts may not use constants, so we have to add helper methods by hand to
  # expose some of the things we need.
  class << self
    extend Forwardable
    def_delegators :Kernel, :rand

    def is_range?(var)
      var.is_a?(Range)
    end
  end
  ScriptMethods.push(*singleton_class.public_instance_methods(false))
end

