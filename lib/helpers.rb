module Helpers
  class Error < RuntimeError
    def initialize(msg, *extra)
      super(msg)
      @extra = extra
    end
    attr_accessor(:extra)
  end
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
