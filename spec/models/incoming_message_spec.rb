require 'rails_helper'

describe IncomingMessage do

  let(:text)     { Faker::Name.name }
  let(:channel)  { create(:channel) }
  let(:user)     { create(:user) }
  let!(:setting) { create(:setting, name: channel.name) }

  let(:message) do
    { channel: channel.slack_id, user: user.slack_id, text: text }.with_indifferent_access
  end

  let(:client) { SlackMock.client_for([user]) }

  subject { described_class.new(message, client) }

  before do
    channel.users << user
  end

  describe '#execute' do
    context 'when standup does not exist' do
      context 'and given the start command' do
        let(:text) { '-start' }

        it 'creates a new standup session' do
          expect { subject.execute }.to change { Standup.count }.by(1)
        end
      end

      context 'and given the help command' do
        let(:text) { '-help' }

        it 'does not create any new messages' do
          expect(client).to receive(:message)

          subject.execute
        end
      end

      context 'and given the vacation command' do
        let(:text) { '-vacation: @santiago' }

        it 'does not create any new messages' do
          expect(client).to_not receive(:message)

          subject.execute
        end
      end

      context 'and given the skip command' do
        let(:text) { '-skip' }

        it 'does not create any new messages' do
          expect(client).to_not receive(:message)

          subject.execute
        end
      end

      context 'and given the quit command' do
        let(:text) { '-quit-standup' }

        it 'does not create any new messages' do
          expect(client).to receive(:message)

          subject.execute
        end
      end

      context 'and given the yes command' do
        let(:text) { '-yes' }

        it 'does not create any new messages' do
          expect(client).to_not receive(:message)

          subject.execute
        end
      end

      context 'and given the delete command' do
        let(:text) { '-delete: 1' }

        it 'does not create any new messages' do
          expect(client).to_not receive(:message)

          subject.execute
        end
      end

      context 'and given the postpone command (skip @user)' do
        let(:text) { '-skip: @santiago' }

        it 'does not create any new messages' do
          expect(client).to_not receive(:message)

          subject.execute
        end
      end
    end

    context 'when standup exists' do
      before { create(:standup, user_id: user.id, channel_id: channel.id) }

      context 'and given the start command' do
        let(:text) { '-start' }

        it 'does not create a new standup session' do
          expect { subject.execute }.to_not change { Standup.count }
        end
      end

      context 'and given the help command' do
        let(:text) { '-help' }

        it 'creates a new message with the expected parameters' do
          expect(client).to receive(:message).with(channel: channel.slack_id, text: I18n.t('activerecord.models.incoming_message.help'))

          subject.execute
        end
      end
    end
  end

end
