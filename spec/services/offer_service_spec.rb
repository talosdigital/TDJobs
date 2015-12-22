require 'rails_helper'
require 'faker'

RSpec.describe OfferService do
  before(:all) do
    @service = OfferService.instance
  end

  describe '.find_by_with_job_filter' do
    context 'when the params doesn\'t include the job filter' do
      let(:params) { Hash.new }
      it 'calls the :find_by method' do
        expect(@service).to receive(:find_by).with(params).and_return([])
        expect(TDJobs::HashQuery).not_to receive(:job_query)
        expect(@service.find_by_with_job_filter(params)).to eq([])
      end
    end

    context 'when no results were found' do
      let(:existent_offer) { create(:offer) }
      let(:existent_job) { existent_offer.job }
      it 'returns an empty array' do
        allow(TDJobs::HashQuery).to receive(:job_query).and_return(name: existent_job.name + 'a')
        allow(@service).to receive(:find_by).and_return(Offer.all)
        allow(Job).to receive(:where).and_return(existent_job)
        allow(TDJobs::HashQuery).to receive(:process_hash).and_return([])
        expect(@service.find_by_with_job_filter(job_filter: '{"name": "you"}')).to be_empty
      end
    end
  end

  describe '.paginated_find' do
    let (:offer1) { build(:offer) }
    let (:offer2) { build(:offer) }
    let (:offer3) { build(:offer) }
    let (:offer4) { build(:offer) }
    context 'when missing page attribute' do
      it 'retrieves all offers' do
        expect(@service).to receive(:find_by_with_job_filter)
          .and_return([offer1, offer2, offer3, offer4])
        response = @service.paginated_find('{"a_valid": "query"}', nil, 2)
        expect(response[:offers]).to eq [offer1, offer2, offer3, offer4]
        expect(response[:total_items]).to eq [offer1, offer2, offer3, offer4].length
        expect(response[:current_page]).to eq 1
        expect(response[:total_pages]).to eq 1
      end
    end

    context 'when missing per_page attribute' do
      it 'retrieves all offers' do
        expect(@service).to receive(:find_by_with_job_filter)
          .and_return([offer1, offer2, offer3, offer4])
        response = @service.paginated_find('{"a_valid": "query"}', 2, nil)
        expect(response[:offers]).to eq [offer1, offer2, offer3, offer4]
        expect(response[:total_items]).to eq [offer1, offer2, offer3, offer4].length
        expect(response[:current_page]).to eq 1
        expect(response[:total_pages]).to eq 1
      end
    end

    context 'when retrieving a valid first page' do
      it 'retrieves that page of offers' do
        matched = Offer.all
        expect(@service).to receive(:find_by_with_job_filter).and_return(matched)
        expect(matched).to receive(:paginate).and_return(matched)
        response = @service.paginated_find('{"a_valid": "query"}', 1, 2)
        expect(response[:offers]).to eq matched
        expect(response[:total_items]).to eq matched.length
        expect(response[:current_page]).to eq 1
        expect(response[:total_pages]).to eq (matched.count.to_f / 2.0).ceil
      end
    end
  end

  describe '.create' do
    context 'when there is no invitation' do
      it 'should create a new offer and OfferEvent' do
        job = create(:job, status: :ACTIVE)
        conditions = ['Condition 1', 'Condition 2']
        offer_attrs = { job_id: job.id, description: 'desc', status: :CREATED,
                        provider_id: Faker::Lorem.word, metadata: { conditions: conditions } }
        expect(Offer).to receive(:create!)
          .with(kind_of(Hash))
          .and_return(build(:offer))

        expect(OfferEvent).to receive(:create)
          .with(kind_of(Hash))
          .and_return(build(:offer_event))

        created_offer = @service.create(offer_attrs)

        expect(created_offer).not_to eq nil
      end
    end

    context 'when is a invitation only Job and there is no invitation' do
      let(:existent_job) { create(:job, status: :ACTIVE, invitation_only: true) }
      let(:offer_attrs) do
        { job_id: existent_job.id, description: 'desc', status: :CREATED,
          provider_id: Faker::Lorem.word }
      end
      let(:conditions) { ['Condition 1', 'Condition 2'] }
      it 'should raise an error' do
        expect(Job).to receive(:find)
          .and_return(existent_job)

        expect { @service.create(offer_attrs) }.to raise_error TDJobs::MissingInvitation
      end
    end

    context 'when there is a valid invitation' do
      let(:existent_job) { create(:active_job, invitation_only: true) }
      let(:invitation) do
        build(:invitation, id: 1,
                           provider_id: Faker::Lorem.word,
                           status: :ACCEPTED,
                           job_id: existent_job.id)
      end
      let(:conditions) { ['Condition 1', 'Condition 2'] }
      let(:offer_attrs) do
        { job_id: existent_job.id, description: 'desc', status: :CREATED,
          provider_id: invitation.provider_id, invitation_id: invitation.id,
          metadata: { conditions: conditions } }
      end
      it 'should create a new offer and OfferEvent' do
        expect(Invitation).to receive(:find)
          .and_return(invitation)

        expect(Offer).to receive(:create!)
          .with(kind_of(Hash))
          .and_return(build(:offer))

        expect(OfferEvent).to receive(:create)
          .with(kind_of(Hash))
          .and_return(build(:offer_event))

        created_offer = @service.create(offer_attrs)

        expect(created_offer).not_to eq nil
      end
    end

    context 'when the invitation provided is non-sent' do
      let(:existent_job) { create(:active_job) }
      let(:invitation) { create(:invitation, job_id: existent_job.id, status: :REJECTED) }
      let(:attributes) do
        { job_id: existent_job.id, description: Faker::Lorem.sentence,
          provider_id: invitation.provider_id, invitation_id: invitation.id }
      end
      it 'should raise an InvalidStatus exception' do
        expect(Job).to receive(:find)
          .with(kind_of Integer)
          .and_return(existent_job)
        expect(Invitation).to receive(:find)
          .with(kind_of Integer)
          .and_return(invitation)
        expect(Offer).not_to receive(:create!)
        expect(OfferEvent).not_to receive(:create)
        expect { OfferService.instance.create(attributes) }.to raise_error TDJobs::InvalidStatus
      end
    end

    context 'when the invitation is for another provider' do
      let(:invitation) { build(:invitation, provider_id:  Faker::Lorem.word) }
      let(:existent_job) { create(:active_job) }
      let(:conditions) { ['Condition 1', 'Condition 2'] }
      let(:offer_attrs) do
        { job_id: existent_job.id, description: 'desc', status: :CREATED,
          provider_id: invitation.provider_id + Faker::Lorem.word, invitation_id: 1,
          metadata: { conditions: conditions } }
      end
      it 'should raise error' do
        expect(Invitation).to receive(:find)
          .and_return(invitation)
        expect { @service.create(offer_attrs) }.to raise_error TDJobs::ProviderMismatch
      end
    end

    context 'when the invitation is for another job' do
      let(:invitation) { build(:invitation, provider_id: Faker::Lorem.word, job_id: 2) }
      let(:existent_job) { create(:active_job) }
      let(:conditions) { ['Condition 1', 'Condition 2'] }
      let(:offer_attrs) do
        { job_id: existent_job.id, description: 'desc', status: :CREATED,
          provider_id: invitation.provider_id,
          invitation_id: 1, metadata: { conditions: conditions } }
      end
      it 'should raise error' do
        expect(Invitation).to receive(:find)
          .and_return(invitation)
        expect { @service.create(offer_attrs) }.to raise_error TDJobs::JobMismatch
      end
    end

    context 'when job provided doesn\'t exist' do
      it 'should raise a RecordNotFound exception' do
        expect(Offer).not_to receive(:create!)
        expect(OfferEvent).not_to receive(:create)
        expect do
          attributes = { job_id: 0, description: Faker::Lorem.sentence, status: :CREATED,
                         provider_id: Faker::Lorem.word }
          OfferService.instance.create(attributes)
        end.to raise_error ActiveRecord::RecordNotFound
      end
    end

    context 'when job provided is not active' do
      it 'should raise an InvalidStatus exception' do
        expect(Offer).not_to receive(:create!)
        expect(OfferEvent).not_to receive(:create)
        expect(Job).to receive(:find)
          .with(kind_of Integer)
          .and_return(build(:closed_job))
        expect do
          attributes = { job_id: 0, description: Faker::Lorem.sentence, status: :CREATED,
                         provider_id: Faker::Lorem.word }
          OfferService.instance.create(attributes)
        end.to raise_error TDJobs::InvalidStatus
      end
    end

    context 'when offer has metadata' do
      let(:metadata) do
        { age_restriction: { max: 35, min: 18 }, allowed_colors: %w(blue green red),
          conditions: ['only for overage', 'worker must have any smartphone'] }
      end
      it 'should create the offer' do
        attributes = { job_id: 0, description: Faker::Lorem.sentence, status: :CREATED,
                       provider_id: Faker::Lorem.word, metadata: metadata }
        expect(Job).to receive(:find)
          .with(kind_of Integer)
          .and_return(build(:job, status: :ACTIVE))
        expect(Offer).to receive(:create!)
          .with(kind_of Hash)
          .and_return(build(:offer))
        expect(OfferEvent).to receive(:create)
        expect { OfferService.instance.create attributes }.not_to raise_error Exception
      end
    end

    context 'when offer doesn\'t have metadata' do
      it 'should create the offer' do
        attributes = { job_id: 0, description: Faker::Lorem.sentence, status: :CREATED,
                       provider_id: Faker::Lorem.word }
        expect(Job).to receive(:find)
          .with(kind_of Integer)
          .and_return(build(:job, status: :ACTIVE))
        expect(Offer).to receive(:create!)
          .with(kind_of Hash)
          .and_return(build(:offer))
        expect(OfferEvent).to receive(:create)
        expect { OfferService.instance.create attributes }.not_to raise_error Exception
      end
    end
  end

  describe '.send' do
    context 'when Offer is not sent' do
      let(:offer) { build(:offer) }

      it 'should send the Offer and create a Offer Event' do
        expect(Offer).to receive(:find).and_return(offer)

        expect(Offer).to receive(:update).with(any_args) do |_id, attrs|
          offer_sent = offer.clone

          attrs.each do |key, value|
            offer_sent[key] = value
          end

          offer_sent
        end

        expect(OfferEvent).to receive(:create)
        offer_updated = @service.send(1)
        expect(offer_updated.status).to eq('SENT')
      end
    end

    context 'when the Offer is sent' do
      let(:offer) { build(:sent_offer) }
      it 'should raise error' do
        expect(Offer).to receive(:find).and_return(offer)
        expect(Offer).not_to receive(:update)
        expect(OfferEvent).not_to receive(:create)
        expect { @service.send(1) }.to raise_error TDJobs::InvalidStatus
      end
    end
  end

  describe '.resend' do
    context 'when Offer is not resent' do
      let(:offer) { build(:returned_offer) }

      it 'should resend the Offer and create an Offer Event and Offer Record' do
        expect(Offer).to receive(:find).and_return(offer)

        expect(Offer).to receive(:update).with(any_args) do |_id, attrs|
          offer_resent = offer.clone

          attrs.each do |key, value|
            offer_resent[key] = value
          end

          offer_resent
        end

        expect(OfferEvent).to receive(:create)
        expect(OfferRecordService.instance).to receive(:create_record).with(kind_of Hash)
        offer_updated = @service.resend(1)
        expect(offer_updated.status).to eq('RESENT')
      end
    end

    context 'when the Offer is not returned' do
      let(:offer) { build(:sent_offer) }
      it 'should raise error' do
        expect(Offer).to receive(:find).and_return(offer)
        expect(Offer).not_to receive(:update)
        expect(OfferEvent).not_to receive(:create)
        expect(OfferRecordService.instance).not_to receive(:create_record)
        expect { @service.resend(1) }.to raise_error TDJobs::InvalidStatus
      end
    end
  end

  describe '.withdraw' do
    context 'when Offer is not withdrawn' do
      let(:offer) { build(:sent_offer) }

      it 'should withdraw the Offer and create a Offer Event' do
        expect(Offer).to receive(:find).and_return(offer)

        expect(Offer).to receive(:update).with(any_args) do |_id, attrs|
          offer_wdrawn = offer.clone

          attrs.each do |key, value|
            offer_wdrawn[key] = value
          end

          offer_wdrawn
        end

        expect(OfferEvent).to receive(:create)
        offer_updated = @service.withdraw(1)
        expect(offer_updated.status).to eq('WITHDRAWN')
      end
    end

    context 'when the Offer is not sent' do
      let(:offer) { build(:created_offer) }
      it 'should raise error' do
        expect(Offer).to receive(:find).and_return(offer)
        expect(Offer).not_to receive(:update)
        expect(OfferEvent).not_to receive(:create)
        expect { @service.withdraw(1) }.to raise_error TDJobs::InvalidStatus
      end
    end
  end

  describe '.return_offer' do
    context 'when Offer is not returned' do
      let(:offer) { build(:sent_offer) }

      it 'should return the Offer and create an Offer Event and Offer Record' do
        expect(Offer).to receive(:find).and_return(offer)

        expect(Offer).to receive(:update).with(any_args) do |_id, attrs|
          offer_returned = offer.clone

          attrs.each do |key, value|
            offer_returned[key] = value
          end

          offer_returned
        end

        expect(OfferEvent).to receive(:create)
        expect(OfferRecordService.instance).to receive(:create_record).with(kind_of Hash)
        offer_updated = @service.return_offer(1)
        expect(offer_updated.status).to eq('RETURNED')
      end
    end

    context 'when the Offer is not sent' do
      let(:offer) { build(:created_offer) }
      it 'should raise error' do
        expect(Offer).to receive(:find).and_return(offer)
        expect(Offer).not_to receive(:update)
        expect(OfferEvent).not_to receive(:create)
        expect(OfferRecordService.instance).not_to receive(:create_record)
        expect { @service.return_offer(1) }.to raise_error TDJobs::InvalidStatus
      end
    end
  end

  describe '.reject' do
    context 'when Offer is not reject' do
      let(:offer) { build(:sent_offer) }

      it 'should reject the Offer and create a Offer Event' do
        expect(Offer).to receive(:find).and_return(offer)

        expect(Offer).to receive(:update).with(any_args) do |_id, attrs|
          offer_rejected = offer.clone

          attrs.each do |key, value|
            offer_rejected[key] = value
          end

          offer_rejected
        end

        expect(OfferEvent).to receive(:create)
        offer_updated = @service.reject(1)
        expect(offer_updated.status).to eq('REJECTED')
      end
    end

    context 'when the Offer is not sent' do
      let(:offer) { build (:created_offer) }
      it 'should raise error' do
        expect(Offer).to receive(:find).and_return(offer)
        expect(Offer).not_to receive(:update)
        expect(OfferEvent).not_to receive(:create)
        expect { @service.reject(1) }.to raise_error TDJobs::InvalidStatus
      end
    end
  end

  describe '.accept' do
    context 'when Offer is not accepted' do
      let(:offer) { build(:sent_offer) }

      it 'should accept the Offer and create a Offer Event' do
        expect(Offer).to receive(:find).and_return(offer)

        expect(Offer).to receive(:update).with(any_args) do |_id, attrs|
          offer_accepted = offer.clone

          attrs.each do |key, value|
            offer_accepted[key] = value
          end

          offer_accepted
        end

        expect(OfferEvent).to receive(:create)
        offer_updated = @service.accept(1)
        expect(offer_updated.status).to eq('ACCEPTED')
      end
    end

    context 'when the Offer is not sent' do
      let(:offer) { build(:created_offer) }
      it 'should raise error' do
        expect(Offer).to receive(:find).and_return(offer)
        expect(Offer).not_to receive(:update)
        expect(OfferEvent).not_to receive(:create)
        expect { @service.accept(1) }.to raise_error TDJobs::InvalidStatus
      end
    end
  end
end
