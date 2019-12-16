class EntityView
  def initialize(all: [], any: [], excl: [])
    @all = all
    @any = any
    @excl = excl
    @comp_map = Hash[*(@all + @any).each_with_index.to_a.flatten]
    @entities = {}
  end

  # match?
  #
  # Checks to see if the provided Entity should show up in this EntityView.
  #
  # Arguments:
  #   entity: An Entity
  #
  def match?(entity)
    all = @all.clone
    any = false
    entity.components.map(&:class).each do |type|
      return false if @excl.include?(type)
      any = true if @any.include?(type)
      all.delete(type)
    end

    (any || @any.empty?) && all.empty?
  end

  # update
  #
  # Notify the view that Entity has changed
  #
  # Arguments:
  #   entity: An Entity
  def update(entity)
    match?(entity) ? add(entity) : @entities.delete(entity.id)
  end

  # add
  #
  # Add an Entity to the view.  This method is primarily exposed for testing;
  # most likely you should be using EntityView#update.
  #
  # Arguments:
  #   entity: Entity to be added
  def add(entity)
    @entities[entity.id] = entity.components.inject([]) do |out,comp|
      if index = @comp_map[comp.class]
        out[index] = comp 
      end
      out
    end
  end

  # each
  #
  # Iterate through all the Entities & Components in the view.
  def each
    return enum_for(:each) unless block_given?

    @entities.each_pair do |id, components|
      yield *[ World.by_id(id), *components ]
    end
  end
end
