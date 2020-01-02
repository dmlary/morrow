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
    ex.backtrace.each do |line|

      # this is a lazy way to do this, but my god, these traces are long.  This
      # will work until I have a better solution.
      break if line.include?('gems/sinatra')

      @logger.error("  " << line)
    end
    true
  end
end
