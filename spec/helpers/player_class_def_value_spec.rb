RSpec.describe 'Helpers.player_class_def_value' do
  let(:entity) { create_entity(base: 'spec:char/actor') }
  let(:char)   { get_component!(entity, :character) }

  before(:all) { reset_world }

  where(:field, :funcs, :result) do
    [ [ :health_regen, [ '{ 1.0 }' ],             1.0 ],
      [ :health_regen, [ '{ 1.0 }', '{ 2.0 }' ],  1.5 ],
      [ :health,       [ '{ 2.0 }', '{ 2.0 }' ],  2.0 ],
    ]
  end

  with_them do
    let(:classes) do
      class_names = %i{ war cle mag thi }
      funcs.inject({}) do |o, func|
        e = create_entity(base: 'morrow:class/base')
        get_component!(e, :class_definition)[field] =
            Morrow::Function.new(func)
        o[class_names.shift] = e
        o
      end
    end

    before do
      allow(Morrow.config).to receive(:classes).and_return(classes)

      char.class_level = {}
      classes.each_key { |k| char.class_level[k] = 1 }
    end

    it 'will return expected result' do
      expect(player_class_def_value(entity, field)).to eq(result)
    end
  end

  context 'entity is not a character' do
    let(:entity) { create_entity() }

    it 'will raise an error' do
      expect { player_class_def_value(entity, :health_regen) }
          .to raise_error(Morrow::InvalidEntity, /not a character/)
    end
  end

  context 'entity is not a player' do
    let(:entity) { create_entity(base: 'spec:char') }

    it 'will raise an error' do
      expect { player_class_def_value(entity, :health_regen) }
          .to raise_error(Morrow::InvalidEntity, /not a player/)
    end
  end
end
