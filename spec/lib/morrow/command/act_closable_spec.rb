describe Morrow::Command::ActClosable do
  before(:each) { reset_world }

  let(:room) { 'spec:room/1' }
  let(:leo) { 'spec:mob/leonidas' }
  let(:chest_closed) { 'spec:obj/chest_closed' }
  let(:output) { strip_color_codes(player_output(leo)) }

  before(:each) do
    move_entity(entity: leo, dest: room)
    player_output(leo).clear
  end

  describe 'open' do
    describe 'exit' do
      context 'that is closed' do
        before(:each) { run_cmd(leo, 'open hidden-cupboard') }

        it 'will open the exit' do
          expect(entity_closed?('spec:room/1/exit/west-to-cupboard'))
              .to be(false)
        end

        it 'will output "You open the hidden-cupboard."' do
          expect(output).to include("You open the hidden-cupboard.")
        end
      end
      context 'that is open' do
        it 'will output "It is already open."' do
          get_component('spec:room/1/exit/west-to-cupboard', :closable)
              .closed = false
          run_cmd(leo, 'open hidden-cupboard')
          expect(output).to include('It is already open.')
        end
      end
    end
    describe 'obj in room' do
      context 'that is closed' do
        before(:each) { run_cmd(leo, 'open chest-closed') }

        it 'will open the chest' do
          expect(entity_closed?('spec:obj/chest_closed'))
              .to be(false)
        end

        it 'will output "You open a wooden chest."' do
          expect(output).to include("You open a wooden chest.")
        end
      end
      context 'that is open' do
        it 'will output "It is already open."' do
          run_cmd(leo, 'open chest-open')
          expect(output).to include('It is already open.')
        end
      end
    end

    describe 'carried obj' do
      context 'that is closed' do
        before(:each) { run_cmd(leo, 'open leo-bag-closed') }

        it 'will open the bag' do
          expect(entity_closed?('spec:mob/leo/bag_closed'))
              .to be(false)
        end

        it 'will output "You open a small bag."' do
          expect(output).to include("You open a small bag.")
        end
      end
      context 'that is open' do
        it 'will output "It is already open."' do
          run_cmd(leo, 'open leo-bag-open')
          expect(output).to include('It is already open.')
        end
      end
    end
  end
end
