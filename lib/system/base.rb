require_relative '../helpers'

module System::Base
  include ::Helpers::Logging

  def send_data(buf, p={})
    entity = p[:entity] || @entity
    conn = entity.get(:connection) or raise RuntimeError,
            'send_line(%s) failed; entity has no connection' %
                entity.inspect
    conn.send_data(buf)
    entity
  end

  def get_room(entity=nil)
    entity ||= @entity
    location_id = entity.get(:location) or return nil
    World.by_id(location_id)
  end

  # Move ++entity_id++ with ++location++ component into ++dest_id++
  def move_to_location(entity_id, dest_id)
    dest = World.by_id(dest_id)
    entity = World.by_id(entity_id)
    source = World.by_id(entity.get(:location))

    source.get(:contents).delete(entity_id) if source
    entity.set(:location, dest_id)
    dest.get(:contents).push(entity_id)
  end
end

__END__

Getting & setting of the entity -> component -> field chain is unwieldy

  entity.component.field = 3    # raises exception if component.nil?

Tried a nil handling approach:

  entity.get_field(component)   # ambiguous

We now have:
  
  entity.set(component, field=:value, value)

So maybe:

  entity.get(component, field=:value)     # => Value

The problem with this approach is that we lose the current #get

  entity.get(component, multiple=false)   # => Component or [ Component, ... ]

Maybe, we just switch #get to #component

  entity.component(component, multiple=false)


API:
component.get(field=:value)           # => value
entity.get(component)                 # => Component    !! CONFLICT !!
entity.get(component, field=:value)   # => value        !! CONFLICT !!

component.set(field=:value, value)    # => component
entity.set(component, field, value)   # => entity


# single component instance and field exists
entity.component.field                # => value
entity.component.field=(value)        # => entity

# single component instance and field does not exist
entity.component.field                # => NoSuchField
entity.component.field=(value)        # => NoSuchField

# no component instance exists
entity.component.field                # => nil
entity.component.field=(value)        # => ComponentNotFound

# multiple components exist
entity.component.field                # => MultipleComponentsFound
entity.component.field=(value)        # => MultipleComponentsFound

Are there cases, where getting `nil` back from `entity.component.field` going
to cause problems?  Yes, any place where `nil` is an acceptable/useful field
for the field.

Is there an alternate method for distinguishing between a `nil` field value and
component not found `nil`?
Yes: `entity.has_component?(component) and entity.component.value`

Is there a cleaner way?

MORE IMPORTANT, can we handle component name overlap with ruby method overlap?
!! NO !!, simple example: class component.  We fucked.

Alright, stop trying to make things pretty and do the set/get syntax.

Single field components, vs multi-field components:
* Adding the default `field=:value` argument to get/set encourages single-field
  components
* I'm not sure that single-field components should be encouraged




EXAMPLES of current code:
  # get all of a type of component from an entity
  exits = room.get(:exit, true).map(&:direction)
  exits = [ 'none' ] if exits.empty?

  # Access to a Component field
  room.get_value(:contents).each { |id| ... }

  # direct access to the Component
  config = @entity.get(:config_options)
  config..class.fields.each { |f| ... }

Capabilities:

  World.by_id(...)    # => Entity
  entity.type         # => etype
  entity.components   # => [ ctype, ctype, ctype, ... ]
  entity.get_comp(ctype, all=false)   # => Component
    # XXX should we throw an exception when there is more than one?
    # Yes, prevent dev from shooting self in foot

  entity.get(ctype, field=:value)   # => value || nil
  entity.set(ctype, field=:value, value)    # => entity || exception

  component.get(field=:value)         # => value || Exception
  component.set(field=:value, value)  # => value || Exception
  component.fields                    # => [ field_1, field_2, ... ]
  component.type                      # => :type

  

