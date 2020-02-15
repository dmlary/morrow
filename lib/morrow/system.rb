# Common module mixed in to all Systems
module Morrow::System
  def self.extended(base)
    base.extend(Morrow::Helpers)
  end
end

require_relative 'system/spawner'
require_relative 'system/input'
