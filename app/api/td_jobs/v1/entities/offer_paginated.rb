module TDJobs
  module V1
    module Entities
      # Maps the Offer model into JSON through Grape.
      class OfferPaginated < Grape::Entity
        expose :total_items, documentation: {
          type: Integer,
          desc: 'The total amount of items including which are not in the current page'
        }
        expose :current_page, documentation: { type: Integer, desc: 'The current page of results' }
        expose :total_pages, documentation: { type: Integer,
                                              desc: 'The total pages that the current query has' }
        expose :offers, using: Entities::Offer, documentation: {
          type: 'array',
          desc: 'The offers in the current page'
        }
      end
    end
  end
end
