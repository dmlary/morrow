require 'logger'
require 'forwardable'

module Morrow::Logging
  extend Forwardable

  class << self
    extend Forwardable

    def_delegators 'Morrow.config.logger', :debug, :info, :warn, :error, :fatal

    def log_exception(ex)
      Morrow.exceptions << ex
      error("#{ex.class}: #{ex.message}")
      ex.backtrace.each do |line|

        # this is a lazy way to do this, but my god, these traces are long.
        # This will work until I have a better solution.
        break if line.include?('gems/sinatra')

        error("  " << line)
      end
      true
    end
  end

  def_delegators 'Morrow.config.logger', :debug, :info, :warn, :error, :fatal
  def_delegators 'Morrow::Logging', :log_exception
end
