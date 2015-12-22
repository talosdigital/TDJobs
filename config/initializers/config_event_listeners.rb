Event::Listener.configure do
  after :job_activated do |job|
    Autoinvite::ProviderConsumer.invite_providers(job) if Autoinvite::ProviderConsumer.is_configured?
  end

  after :invitation_created do |invitation|
    AutoSendInvitation::InvitationSender.send_invitation(invitation) if TDJobs.configuration.auto_send_invitation?
  end
  
end
