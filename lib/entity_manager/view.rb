class EntityManager::View
  def initialize(all: [], any: [], excl: [])
    @required = all.map { |i,k| [ i, k, k.unique? ] }
    @optional = any.map { |i,k| [ i, k, k.unique? ] }
    @exclude  = excl.map { |i,k| [ i, k, k.unique? ] }
    @entities = {}
  end

  # update!
  #
  # Notify the view that a given Entity has been modified.  This method will
  # either remove the Entity from the view, or update the Entity record for the
  # Components this view tracks.
  #
  # Arguments:
  #   entity: Entity that has been updated
  def update!(entity, components)
    excluded = @exclude.find { |i,_| components[i] }
    entry = nil

    if !excluded
      entry = @required.inject([]) do |o,(i,_,unique)|
        v = components[i] or break nil
        o << (unique ? v : (v || []))
      end
    end

    if entry && !@optional.empty?
      found = false
      @optional.each do |i,_,unique|
        v = components[i]
        found = true if v != nil
        entry << (unique ? v : (v || []))
      end
      entry = nil unless found
    end

    if entry
      @entities[entity] = entry
    else
      @entities.delete(entity)
    end
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
