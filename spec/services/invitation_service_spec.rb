require 'rails_helper'

RSpec.describe InvitationService do

  describe '.find_by_with_job_filter' do
    context 'when the params doesn\'t include the job filter' do
      let(:params) { Hash.new }
      it 'calls the :find_by method' do
        expect(InvitationService.instance).to receive(:find_by).with(params).and_return([])
        expect(TDJobs::HashQuery).not_to receive(:job_query)
        expect(InvitationService.instance.find_by_with_job_filter(params)).to eq([])
      end
    end

    context 'when no results were found' do
      let(:existent_invitation) { create(:invitation) }
      let(:existent_job) { existent_invitation.job }
      it 'returns an empty array' do
        allow(TDJobs::HashQuery).to receive(:job_query).and_return(name: existent_job.name + 'a')
        allow(InvitationService.instance).to receive(:find_by).and_return(Invitation.all)
        allow(Job).to receive(:where).and_return(existent_job)
        allow(TDJobs::HashQuery).to receive(:process_hash).and_return([])
        expect(InvitationService.instance.find_by_with_job_filter(job_filter: '{"name": "you"}'))
          .to be_empty
      end
    end
  end

  describe '.paginated_find' do
    let (:invitation1) { build(:invitation) }
    let (:invitation2) { build(:invitation) }
    let (:invitation3) { build(:invitation) }
    let (:invitation4) { build(:invitation) }
    context 'when missing page attribute' do
      it 'retrieves all invitations' do
        expect(InvitationService.instance).to receive(:find_by_with_job_filter)
          .and_return([invitation1, invitation2, invitation3, invitation4])
        response = InvitationService.instance.paginated_find('{"a_valid": "query"}', nil, 2)
        expect(response[:invitations]).to eq [invitation1, invitation2, invitation3, invitation4]
        expect(response[:total_items]).to eq [invitation1, invitation2,
                                              invitation3, invitation4].count
        expect(response[:current_page]).to eq 1
        expect(response[:total_pages]).to eq 1
      end
    end

    context 'when missing per_page attribute' do
      it 'retrieves all invitations' do
        expect(InvitationService.instance).to receive(:find_by_with_job_filter)
          .and_return([invitation1, invitation2, invitation3, invitation4])
        response = InvitationService.instance.paginated_find('{"a_valid": "query"}', 2, nil)
        expect(response[:invitations]).to eq [invitation1, invitation2, invitation3, invitation4]
        expect(response[:total_items]).to eq [invitation1, invitation2,
                                              invitation3, invitation4].length
        expect(response[:current_page]).to eq 1
        expect(response[:total_pages]).to eq 1
      end
    end

    context 'when retrieving a valid first page' do
      it 'retrieves that page of offers' do
        matched = Invitation.all
        expect(InvitationService.instance).to receive(:find_by_with_job_filter).and_return(matched)
        expect(matched).to receive(:paginate).and_return(matched)
        response = InvitationService.instance.paginated_find('{"a_valid": "query"}', 1, 2)
        expect(response[:invitations]).to eq matched
        expect(response[:total_items]).to eq matched.length
        expect(response[:current_page]).to eq 1
        expect(response[:total_pages]).to eq (matched.count.to_f / 2.0).ceil
      end
    end
  end

  describe '.find_by' do
    context 'when no param is send' do
      it 'should call Invitation.order' do
        expect(Invitation).to receive(:order)
          .and_return({})
        expect(Invitation).to receive(:where)
          .exactly(0).times
        InvitationService.instance.find_by({})
      end
    end

    context 'when status param is a string' do
      let(:params){
        {status: "ACTIVE"}
      }
      it 'should call Invitation.order and where' do
        mock_query = double('query')
        expect(Invitation).to receive(:order)
          .and_return(mock_query)

        expect(mock_query).to receive(:where)
          .with(kind_of(String), kind_of(String))
          .exactly(1).times
        InvitationService.instance.find_by(params)
      end
    end

    context 'when status param is a Array' do
      let(:params){
        {status: ["ACTIVE","SENT"]}
      }
      it 'should call Invitation.order and where' do
        mock_query = double('query')
        expect(Invitation).to receive(:order)
          .and_return(mock_query)

        expect(mock_query).to receive(:where)
          .with(kind_of(String), kind_of(Array))
          .exactly(1).times
        InvitationService.instance.find_by(params)
      end
    end

  end

  describe '.create_new' do
    context 'when attributes are correct' do
      it 'creates a new invitation' do
        allow(Invitation).to receive(:create!)
          .with(kind_of Hash)
          .and_return(build(:invitation))
        allow(Job).to receive(:find)
          .with(kind_of Integer)
          .and_return(build(:job, status: :ACTIVE))
        expect(InvitationEvent).to receive(:create)
        expect do
          InvitationService.instance.create_new(provider_id: "hey", job_id: 0)
        end.not_to raise_error Exception
      end
    end

    context 'when provider_id is nil' do
      let(:existent_job) { create(:job, status: :ACTIVE) }
      it 'should return a RecordInvalid exception' do
        expect(Job).to receive(:find)
          .with(kind_of Integer)
          .and_return(existent_job)
        expect do
          InvitationService.instance.create_new(job_id: existent_job.id)
        end.to raise_error ActiveRecord::RecordInvalid
      end
    end

    context 'when job provided doesn\'t exist' do
      it 'should raise a RecordNotFound exception' do
        expect(Invitation).not_to receive(:create!)
        expect(InvitationEvent).not_to receive(:create)
        expect do
          InvitationService.instance.create_new(provider_id: "hey", job_id: 0)
        end.to raise_error ActiveRecord::RecordNotFound
      end
    end

    context 'when job provided is not active' do
      it 'should raise an InvalidStatus exception' do
        expect(Invitation).not_to receive(:create!)
        expect(InvitationEvent).not_to receive(:create)
        expect(Job).to receive(:find)
          .with(kind_of Integer)
          .and_return(build(:job, status: :CLOSED))
        expect do
          InvitationService.instance.create_new(provider_id: "hey", job_id: 0)
        end.to raise_error TDJobs::InvalidStatus
      end
    end
  end

  describe '.send' do
    context 'when it can be sent' do
      let(:invitation) { build :invitation, status: :CREATED }
      it 'returns the sent invitation' do
        allow(Invitation).to receive(:find)
          .with(kind_of Fixnum)
          .and_return(invitation)
        allow(Invitation).to receive(:update)
          .with(kind_of(Fixnum), kind_of(Hash))
          .and_return(invitation)
        expect(InvitationEvent).to receive(:create)
        expect { InvitationService.instance.send 0 }.not_to raise_error Exception
      end
    end

    context 'when the status indicates it can\'t be sent' do
      it 'raises an InvalidStatus exception' do
        allow(Invitation).to receive(:find)
          .with(kind_of Fixnum)
          .and_return(build :invitation, status: :SENT)
        expect(InvitationEvent).not_to receive(:create)
        expect { InvitationService.instance.send 0 }.to raise_error TDJobs::InvalidStatus
      end
    end
  end

  describe '.withdraw' do
    context 'when it can be withdrawn' do
      let(:invitation) { build :invitation, status: :CREATED }
      it 'returns the updated invitation' do
        allow(Invitation).to receive(:find)
          .with(kind_of Fixnum)
          .and_return(invitation)
        allow(Invitation).to receive(:update)
          .with(kind_of(Fixnum), kind_of(Hash))
          .and_return(invitation)
        expect(InvitationEvent).to receive(:create)
        expect { InvitationService.instance.withdraw 0 }.not_to raise_error Exception
      end
    end

    context 'when the status indicates it can\'t be withdrawn' do
      it 'raises an InvalidStatus exception' do
        allow(Invitation).to receive(:find)
          .with(kind_of Fixnum)
          .and_return(build :invitation, status: :WITHDRAWN)
        expect(InvitationEvent).not_to receive(:create)
        expect { InvitationService.instance.withdraw 0 }.to raise_error TDJobs::InvalidStatus
      end
    end
  end

  describe '.accept' do
    context 'when it can be accepted' do
      let(:invitation) { build :invitation, status: :SENT }
      it 'returns the updated invitation' do
        allow(Invitation).to receive(:find)
          .with(kind_of Fixnum)
          .and_return(invitation)
        allow(Invitation).to receive(:update)
          .with(kind_of(Fixnum), kind_of(Hash))
          .and_return(invitation)
        expect(InvitationEvent).to receive(:create)
        expect { InvitationService.instance.accept 0 }.not_to raise_error Exception
      end
    end

    context 'when the status indicates it can\'t be accepted' do
      it 'raises an InvalidStatus exception' do
        allow(Invitation).to receive(:find)
          .with(kind_of Fixnum)
          .and_return(build :invitation, status: :ACCEPTED)
        expect(InvitationEvent).not_to receive(:create)
        expect { InvitationService.instance.accept 0 }.to raise_error TDJobs::InvalidStatus
      end
    end
  end

  describe '.reject' do
    context 'when it can be rejected' do
      let(:invitation) { build :invitation, status: :SENT }
      it 'returns the updated invitation' do
        allow(Invitation).to receive(:find)
          .with(kind_of Fixnum)
          .and_return(invitation)
        allow(Invitation).to receive(:update)
          .with(kind_of(Fixnum), kind_of(Hash))
          .and_return(invitation)
        expect(InvitationEvent).to receive(:create)
        expect { InvitationService.instance.reject 0 }.not_to raise_error Exception
      end
    end

    context 'when the status indicates it can\'t be rejected' do
      let(:invitation) { build :invitation, status: :REJECTED }
      it 'raises an InvalidStatus exception' do
        allow(Invitation).to receive(:find)
          .with(kind_of Fixnum)
          .and_return(invitation)
        expect(InvitationEvent).not_to receive(:create)
        expect { InvitationService.instance.reject 0 }.to raise_error TDJobs::InvalidStatus
      end
    end
  end
end
