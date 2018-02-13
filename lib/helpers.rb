module Helpers
end

require_relative 'helpers/attributes'
require_relative 'helpers/loadable'
require_relative 'helpers/logging'
require_relative 'helpers/database'

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
