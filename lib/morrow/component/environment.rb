# Environmental details for a room/container.  These things impact the
# entities within the ContainerComponent.contents
class Morrow::Component::Environment < Morrow::Component
  desc <<~DESC
  DESC

  # Terrain type within a room
  field :terrain,
      type: Symbol,
      valid: %i{ inside city field forest hills mountains
                 water_swim water_noswim air underwater
                 desert },
      default: :forest
end
