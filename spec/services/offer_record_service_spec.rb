require 'rails_helper'

RSpec.describe OfferRecordService do
  before :all do
    @offer_record = create :offer_record
  end

  describe '.create_record' do
    context 'when offer_id is missing' do
      it 'should raise ArgumentError' do
        expect do
          OfferRecordService.instance.create_record(offer_id: nil)
        end.to raise_error ArgumentError
      end
    end

    context 'when record_type is missing' do
      it 'should raise ArgumentError' do
        expect do
          OfferRecordService.instance.create_record(record_type: nil)
        end.to raise_error ArgumentError
      end
    end

    context 'when metadata is missing' do
      it 'should raise ArgumentError' do
        expect do
          OfferRecordService.instance.create_record(metadata: nil)
        end.to raise_error ArgumentError
      end
    end

    context 'when record_type is not valid' do
      let(:offer) { create :offer }
      it 'should raise TDJobs::InvalidRecordType' do
        expect do
          OfferRecordService.instance.create_record(offer: offer, record_type: :SINGLE_RECORD,
                                                    metadata: {})
        end.to raise_error TDJobs::InvalidRecordType
      end
    end

    context 'when the attrs are valid' do
      let(:offer) { create :offer }
      it 'should create the record' do
        expect(OfferRecord).to receive :create!
        OfferRecordService.instance.create_record(offer: offer,
                                                  reason: 'A very coherent reason',
                                                  record_type: :RESENT,
                                                  metadata: {})
      end
    end
  end
end
