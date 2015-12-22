module AutoSendInvitation
  class InvitationSender
    def self.send_invitation(invitation)
      InvitationService.instance.send(invitation.id)
    end
  end
end