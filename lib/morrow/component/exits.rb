# Maintains the list of exits from a location; one for each cardinal direction
# used in the world.  Additionally keeps reference to any doors that bar each
# exit.
class Morrow::Component::Exits < Morrow::Component

  Morrow::Helpers.exit_directions.each do |dir|
    field dir, type: :entity, desc: 'room to which this exit leads'
    field "#{dir}_door", type: :entity,
        desc: "door barring exit to the #{dir}"
  end
end
