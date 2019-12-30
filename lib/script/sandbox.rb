# Sandbox
#
# Sandbox in which scripts get evaluated.  All methods in the ScriptMethods
# array are available for the script to use.
module Script::Sandbox

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
  ScriptMethods = [ :entity, :actor ]

  # Pull in the standard logging functions
  extend Helpers::Logging
  ScriptMethods.push(*::Helpers::Logging.public_instance_methods(false))
  ScriptMethods.delete(:logger)   # but they don't need the logger method

  # explicitly pull in World::ScriptSafeHelpers
  extend ::World::ScriptSafeHelpers
  ScriptMethods
      .push(*::World::ScriptSafeHelpers.public_instance_methods(false))

  # Scripts may not use constants, so we have to add helper methods by hand to
  # expose some of the things we need.
  class << self
    extend Forwardable
    def_delegators :Time, :now
    def_delegators :Kernel, :rand
  end
  ScriptMethods.push(*singleton_class.public_instance_methods(false))
end

