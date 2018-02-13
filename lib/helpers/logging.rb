require 'logger'
require 'forwardable'

module Helpers::Logging
  extend Forwardable

  def_delegators :logger, :debug, :info, :warn, :error, :fatal

  def self.logger
    @logger ||= Logger.new(STDERR)
  end

  def self.logger=(logger)
    @logger = logger
  end

  def logger
    Helpers::Logging.logger
  end
end
