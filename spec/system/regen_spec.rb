describe Morrow::System::Regen do
  before(:all) { reset_world }
  let(:entity) { create_entity(base: 'spec:char') }
  let(:resources) { get_component!(entity, :character) }

  [ { desc: 'entity at max health, rate is positive',
      resource: :health,
      max: 100,
      before: 100,
      regen: 1,
      after: 100 },
      { desc: 'entity at max health, rate is -10%',
      resource: :health,
      max: 100,
      before: 100,
      regen: -0.1,
      after: 90 },
    { desc: 'entity at 90/100 health, regen is 20%',
      resource: :health,
      max: 100,
      before: 90,
      regen: 0.20,
      after: 100 },
    { desc: 'entity at 70/100 health, regen is 20%',
      resource: :health,
      max: 100,
      before: 70,
      regen: 0.20,
      after: 90 },
    { desc: 'entity at 120/100 health, regen is 10%; preserve temp hitpoints',
      resource: :health,
      max: 100,
      before: 120,
      regen: 0.10,
      after: 120 },
  ].each do |t|
    context t[:desc] do
      before(:each) do
        max_key = ('%s_max' % t[:resource]).to_sym
        regen_key = ('%s_regen' % t[:resource]).to_sym
        resources[t[:resource]] = t[:before]
        resources[max_key] = t[:max]
        resources[regen_key] = t[:regen]

        described_class.update(entity, resources)
      end

      if t[:before] != t[:after]
        it 'will change %s to %d' % [ t[:resource], t[:after] ] do
          expect(resources[t[:resource]]).to eq(t[:after])
        end
      else
        it 'will not change %s' % [ t[:resource] ] do
          expect(resources[t[:resource]]).to eq(t[:before])
        end
      end
    end
  end
end
