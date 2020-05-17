describe 'Morrow::Helpers.char_health_base' do
  let(:char) { create_entity(base: 'spec:char/actor') }
  let(:char_comp) { get_component!(char, :character) }

  before(:all) { reset_world }

  context 'entity is not a character' do
    it 'will raise InvalidEntity' do
      ball = create_entity(base: 'spec:obj/ball')
      expect { char_health_base(ball) }
          .to raise_error(Morrow::InvalidEntity)
    end
  end

  [ { desc: 'single class; passes level to func',
      classes: {
        warrior: { level: 10, func: '{ |l| l * 25 }' }
      },
      expect: 250 },
    { desc: 'dual class; average health funcs',
      classes: {
        warrior: { level: 1, func: '{ 25 }' },
        thief:   { level: 5, func: '{ 10 }' },
      },
      expect: 17 },
    { desc: 'con bonus of 1.1; con modifier is applied',
      classes: {
        warrior: { level: 10, func: '{ 100 }' },
      },
      con_mod: 1.1,
      expect: (100 * 1.1).to_i },
  ].each do |t|
    context t[:desc] do

      let(:class_defs) do
        t[:classes].inject({}) do |o, (name, cfg)|
          e = create_entity(base: 'morrow:class')
          c = get_component!(e, :class_definition)
          c.health_func = Morrow::Function.new(cfg[:func])
          o[name] = c
          o
        end
      end

      before(:each) do

        char_comp.class_level = {}
        t[:classes].each do |name, cfg|
          char_comp.class_level[name] = cfg[:level]
        end

        allow(self).to receive(:class_def) do |name|
          class_defs[name]
        end

        allow(self).to receive(:char_con_modifier) do
          t[:con_mod] ? t[:con_mod] : 1.0
        end
      end

      it 'will return %d' % t[:expect] do
        expect(char_health_base(char)).to eq(t[:expect])
      end
    end
  end
end
