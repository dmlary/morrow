class EntityView
  def initialize(all: [], any: [], excl: [])
    @entities = {}
    @comp_map = {}
    all.each  { |c| @comp_map[c] = [ @comp_map.size, :required, c.unique? ] }
    any.each  { |c| @comp_map[c] = [ @comp_map.size, :optional, c.unique? ] }
    excl.each { |c| @comp_map[c] = [ @comp_map.size, :excluded, c.unique? ] }

    @required = all
    @optional = any
  end

  # update!
  #
  # Notify the view that a given Entity has been modified.  This method will
  # either remove the Entity from the view, or update the Entity record for the
  # Components this view tracks.
  #
  # Arguments:
  #   entity: Entity that has been updated
  def update!(entity)
    required = @required.clone
    optional_found = false

    # If this entity is tracked in the view, remove it now
    @entities.delete(entity.id)

    # Construct an empty entry for this view
    base = @comp_map.map { |c,(_,_,uniq)| uniq ? nil : [] }

    # flesh out the entry with the components in the Entity
    entry = entity.components.inject(base) do |out,comp|
      index, type, uniq = @comp_map[comp.class]

      next out unless index

      case type
      when :excluded
        return false
      when :optional
        optional_found = true
      when :required
        required.delete(comp.class)
      else
        raise "unknown type #{type}"
      end

      if uniq
        out[index] = comp
      else
        out[index] << comp
      end

      out
    end

    return false unless required.empty?
    return false unless @optional.empty? or optional_found

    @entities[entity.id] = entry
    self
  end

  # each
  #
  # Iterate through all the Entities & Components in the view.
  def each
    return enum_for(:each) unless block_given?

    @entities.each_pair do |id, components|
      yield([ id, *components ])
    end
  end
end
