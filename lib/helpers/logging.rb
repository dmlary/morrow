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

  def self.log_exception(ex)
    @logger.error("#{ex.class}: #{ex.message}")
    ex.backtrace.each { |l| @logger.error("  " << l) }
    true
  end
end
