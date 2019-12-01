module Helpers
end

require_relative 'helpers/logging'

# detect & fix ruby bug #13145
begin
  :symbol.clone
rescue TypeError
  class Symbol
    def clone
      self
    end
  end
end
