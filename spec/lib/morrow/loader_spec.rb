describe Morrow::Loader do
  let(:em) do
    Morrow::EntityManager.new(components: Morrow.config.components)
  end

  context 'file contains an update to an existing entity' do
    # We set up the following scenario:
    # * create a base entity that has the player_config component
    # * create the entity to be updated with the exits component
    #
    # Load a file that updates the entity to:
    # * add 'base' as a base
    # * update 'exits.east' to be 'passed'
    # * add the spawn component
    #
    before(:each) do
      em.create_entity(id: 'base', components: :player_config)
      em.create_entity(id: 'entity', components: :exits)

      loader = described_class.new(em)
      loader.load_file(File .expand_path('../loader_entity_update.yml',
          __FILE__))
      loader.finalize
    end

    it 'will not create a new entity' do
      expect(em.entities.keys).to contain_exactly('base', 'entity')
    end

    it 'will update component in the original entity' do
      expect(em.get_component('entity', :exits).east).to eq('passed')
    end

    it 'will add new components to the original entity' do
      expect(em.get_component('entity', :spawn)).to_not be_nil
    end

    it 'will add components from added bases' do
      expect(em.get_component('entity', :player_config)).to_not be_nil
    end

    it 'will update the metadata to denote the new base'
  end
end
