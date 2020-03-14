# Common module mixed in to all Systems
module Morrow::System
  def self.extended(base)
    base.extend(Morrow::Helpers)

    base.instance_eval do
      @system_perf = Array.new(4*60*15)   # 15 minutes of data
      @system_perf_lag = Array.new(25)    # last 25 lag events
    end
  end

  # How frequently this system will run in seconds.  The default frequency for
  # all systems is to run each update interval.
  def frequency
    Morrow.config.update_interval
  end

  # Update the performance data for this Module.  Called from Morrow.update.
  def append_system_perf(bm)
    @system_perf << [now, bm]
    @system_perf.shift

    if bm.real > 0.25
      @system_perf_lag << [now, bm]
      @system_perf_lag.shift
    end
  end

  # Get the performance data for this system
  def system_perf
    @system_perf.compact
  end

  # Get latest lag events for this system
  def system_perf_lag_events
    @system_perf_lag.compact
  end
end

require_relative 'system/spawner'
require_relative 'system/input'
require_relative 'system/connection'
require_relative 'system/teleport'
require_relative 'system/combat'
require_relative 'system/decay'
