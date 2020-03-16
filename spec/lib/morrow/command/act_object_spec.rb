describe Morrow::Command::ActObject do
  let(:room) { 'spec:room/act_object' }
  let(:leo) { 'spec:mob/leonidas' }
  let(:observer) { 'spec:char/observer' }
  let(:ball) { create_entity(base: 'spec:obj/junk/ball') }
  let(:fountain) { create_entity(base: 'spec:obj/fountain') }

  before(:each) do
    reset_world
    move_entity(entity: leo, dest: room)
    get_component!(leo, :container).max_weight = 100
    player_output(leo).clear

    move_entity(entity: observer, dest: room)
    player_output(observer).clear
    move_entity(entity: ball, dest: room)
    move_entity(entity: fountain, dest: room)
  end

  describe 'get' do
    describe '<keyword>' do
      context 'object does not exist' do
        it 'will output an error to the actor' do
          expect(cmd_output(leo, 'get missing'))
              .to include('You do not see a missing here.')
        end
      end

      context 'object is animate' do
        it 'will output an error to the actor' do
          expect(cmd_output(leo, 'get observer'))
              .to include('You do not see an observer here.')
        end
      end
      context 'object is inanimate' do
        context 'object is not corporeal' do
          before(:each) do
            remove_component(ball, :corporeal)
            run_cmd(leo, 'get ball')
          end
          it 'will output an error to the actor' do
            expect(player_output(leo)).to \
                include('Your hand passes right through a red rubber ball!')
          end
          it 'will not move the object' do
            expect(entity_location(ball)).to eq(room)
          end
        end

        context 'object is too heavy' do
          before(:each) { run_cmd(leo, 'get fountain') }
          it 'will output an error to the actor' do
            expect(player_output(leo))
                .to include('A marble fountain is too heavy for you to take.')
          end
          it 'will not move the object' do
            expect(entity_location(fountain)).to eq(room)
          end
        end

        context 'actor is at max volume' do
          before(:each) do
            get_component!(leo, :container).max_volume = 0
            run_cmd(leo, 'get ball')
          end
          it 'will output an error to the actor' do
            expect(player_output(leo)).to include('Your hands are full.')
          end
          it 'will not move the object' do
            expect(entity_location(ball)).to eq(room)
          end
        end

        context 'object is not too heavy and actor has space' do
          before(:each) { run_cmd(leo, 'get ball') }
          it 'will send output to the actor' do
            expect(player_output(leo))
                .to include('You pick up a red rubber ball.')
          end
          it 'will notify the observer' do
            expect(player_output(observer))
                .to include('Leonidas picks up a red rubber ball.')
          end
          it 'will move the object into the actor\'s inventory' do
            expect(entity_location(ball)).to eq(leo)
          end
        end
      end
    end
    describe '<object> <container>' do
      context 'container does not exist' do
        it 'will output an error to actor'
      end
      context '<container> is not a container' do
        it 'will output an error to actor'
      end
      context '<object> is not in <container>' do
        it 'will output an error to actor'
      end
      context 'actor is at max volume' do
        it 'will output an error to actor'
        it 'will not move <object>'
      end
      context 'actor is at max weight' do
        it 'will move <object>'
        it 'will output a message to actor'
        it 'will output a message to observer'
      end
    end
  end
end
