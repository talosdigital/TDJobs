# Contains all OfferRecord managing logic.
class OfferRecordService
  include Singleton

  # Creates a new OfferRecord.
  # @param [Hash] attrs the hash containing the Offer and the record type.
  # @option attrs [Offer] :offer the offer whose record will be persisted.
  # @option attrs [Symbol] :record_type The type of record (:CREATED, :RETURNED, :RESENT)
  # @option attrs [String] :reason the reason for the offer to be created, returned or resent.
  # @return OfferRecord
  # @raise [ArgumentError] when no :offer or :record_type are specified.
  # @raise [TDJobs::InvalidRecordType] when :record_type is not a valid type.
  def create_record(attrs)
    unless attrs[:offer] && attrs[:record_type]
      raise ArgumentError, "You should provide an offer and a reason to create an OfferRecord"
    end
    unless [:CREATED, :RETURNED, :RESENT].include?(attrs[:record_type].to_sym)
      raise TDJobs::InvalidRecordType, "The record type '#{attrs[:record_type]}' is not valid"
    end
    OfferRecord.create!(offer: attrs[:offer],
                       record_type: attrs[:record_type],
                       reason: attrs[:reason],
                       metadata: attrs[:offer][:metadata])
  end
end
