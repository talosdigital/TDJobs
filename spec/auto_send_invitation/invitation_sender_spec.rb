require 'rails_helper'

RSpec.describe AutoSendInvitation::InvitationSender do

  describe 'send_invitation' do
    context '' do
      let(:invitation) { build :invitation, id: 1, status: :CREATED }

      it 'should send invitation' do

        allow(Invitation).to receive(:find)
          .with(kind_of Fixnum)
          .and_return(invitation)
        allow(Invitation).to receive(:update)
          .with(kind_of(Fixnum), kind_of(Hash))
          .and_return(invitation)
        expect(InvitationEvent).to receive(:create)  

        expect { AutoSendInvitation::InvitationSender.send_invitation(invitation) }.not_to raise_error Exception
      end
    end
  end

end