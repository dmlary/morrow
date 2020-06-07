# System for regenerating character resources
#
# Note that the #update method here has been unrolled for performance reasons.
# To add a new resource type for rengeration, subclass this system and call
# super, then update any additional resources.
module Morrow::System::Regen
  extend Morrow::System

  class << self
    def frequency
      1
    end

    def view
      { all: :character }
    end

    def update(entity, resources)

      # For performance reasons, we manually implement each of these different
      # resource updates.
      curr = resources.health
      max  = resources.health_max
      regen = resources.health_regen

      if regen < 0 or curr < max
        adj = curr + max * regen
        resources.health = adj > max ? max : adj
      end
    end
  end
end
