require 'logger'
require 'forwardable'

module Morrow::Logging
  extend Forwardable

  class << self
    extend Forwardable

    def_delegators 'Morrow.config.logger', :debug, :info, :warn, :error, :fatal

    def log_exception(ex)
      Morrow.exceptions << ex
      ex.full_message(order: :bottom, highlight: false)
          .lines.each { |l| error(l.chomp) }
      true
    end
  end

  def_delegators 'Morrow.config.logger', :debug, :info, :warn, :error, :fatal
  def_delegators 'Morrow::Logging', :log_exception
end
