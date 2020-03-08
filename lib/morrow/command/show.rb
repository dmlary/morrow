require 'facets/array/average'
require 'facets/array/last'

module Morrow::Command::Show
  extend Morrow::Command

  class << self
    # Show administrative details about the mud server
    #
    # Syntax: show <section>
    #
    # Examples:
    #   show systems
    #
    def show(actor, arg)
      command_error 'Usage: show <systems>' unless arg

      buf = if 'system'.start_with?(arg)
        show_systems
      else
        command_error "Unknown argument: #{arg}"
      end

      send_to_char(char: actor, buf: buf.chomp)
    end

    private

    def show_systems
      buf = Morrow.config.systems.inject('') do |out,system|
        out << "&W#{system}&0:\n"

        all  = system.system_perf.map { |_,bm| bm.to_a[1..] }
        one  = all.last(60 * 4)
        five = all.last(5 * 60 * 4)

        { '1 min' => one, '5 min' => five, '15 min' => all }
            .each do |label,perf|
          perf = perf.transpose

          utime = perf[1].average
          stime = perf[2].average
          real  = perf[-1].average
          out << "  %6s: real %0.04f, utime %0.04f, stime %0.04f\n" %
              [ label, real, utime, stime ]
        end

        lag = system.system_perf_lag_events
        unless lag.empty?
          out << "  lag events (up to the last 25 events):\n"
          lag.each do |ts,bm|
            out << "    %s: real %0.04f, utime %0.04f, stime %0.04f\n" %
                [ ts.strftime("%FT%T.%3N%z"), bm.real, bm.utime, bm.stime ]
          end
        end

        out
      end
    end
  end
end
