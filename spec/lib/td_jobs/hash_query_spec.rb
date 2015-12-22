require 'rails_helper'
require 'faker'

describe TDJobs::HashQuery do
  let(:hash_query) { TDJobs::HashQuery }
  let(:all_jobs) do
    Faker::Number.between(2, 10).times { create(:job) }
    Job.all
  end
  let(:found_job) { create(:job, metadata: { my_field: "First field", number_field: 20 } ) }

  describe '.process_hash' do
    context 'always' do
      let(:parameters) do
        { hello: "hi", morning: "you", metadata: { some: "thing" } }
      end
      it 'calls .build_query with the given parameters' do
        expect(hash_query).to receive(:build_query).with(parameters, []).and_return(["", []])
        allow(all_jobs).to receive(:where)
        hash_query.process_hash(all_jobs, parameters)
      end

      it 'calls results.where with response from .build_query' do
        allow(hash_query).to receive(:build_query)
          .with(parameters, [])
          .and_return(["hello", ["hey"]])
        expect(all_jobs).to receive(:where)
          .with("hello", "hey")
        hash_query.process_hash(all_jobs, parameters)
      end
    end

    context 'when metadata filter matches only 1 job' do
      let(:filter) do
        { metadata: { my_field: { like: "Fi"}, number_field: { geq: 19, lt: 21} } }
      end
      it 'returns the matched job' do
        expect(hash_query.process_hash(all_jobs, filter)).to eq [found_job]
      end
    end

    context 'when filter doesn\'t match any job' do
      let(:filter) do
        { description: "You won't find this", status: { in: [:CLOSED.to_s] } }
      end
      it 'returns an empty array' do
        expect(hash_query.process_hash(all_jobs, filter)).to eq []
      end
    end
  end

  describe '.build_query' do
    context 'when the filter is empty' do
      it 'returns an empty query with no injections' do
        expect(hash_query.build_query({}, [])).to eq ["", []]
      end
    end

    context 'when filter has no nested keys' do
      it 'doesn\'t call build_query more than once' do
        expect(hash_query).to receive(:build_query).once
        hash_query.build_query({ status: "ACTIVE" }, [])
      end
    end

    context 'when a key is $or' do
      let(:parameters) do
        { "$or" => { status: "ACTIVE", name: "hello" }}
      end
      it 'calls .handle_association method' do
        expect(hash_query).to receive(:handle_association)
          .with(parameters["$or"], [], :OR).once.and_return(["", []])
        hash_query.build_query(parameters, [])
      end
    end

    context 'when a key is $and' do
      let(:parameters) do
        { "$and" => { status: "ACTIVE", name: "hello" }}
      end
      it 'calls .handle_association method' do
        expect(hash_query).to receive(:handle_association)
          .with(parameters["$and"], [], :AND).once.and_return(["", []])
        hash_query.build_query(parameters, [])
      end
    end

    context 'when the filter is only one valid key with string value' do
      let(:parameters) do
        { status: "ACTIVE" }
      end
      it 'calls .build_prefix with base and the key' do
        expect(hash_query).to receive(:build_prefix).with([], :status)
        hash_query.build_query(parameters, [])
      end
    end

    context 'when the filter is only one valid key with double value' do
      let(:parameters) do
        { status: 2.0 }
      end
      it 'calls .build_prefix with base and the key' do
        expect(hash_query).to receive(:build_prefix).with([], :status)
        hash_query.build_query(parameters, [])
      end
    end

    context 'when the filter is only one valid key with integer value' do
      let(:parameters) do
        { status: 55 }
      end
      it 'calls .build_prefix with base and the key' do
        expect(hash_query).to receive(:build_prefix).with([], :status)
        hash_query.build_query(parameters, [])
      end
    end

    context 'when using multiple recursivity levels' do
      let(:filter) do
        { metadata: { sports: { favorite: { summer: "aaa"} } } }
      end
      it 'calls times the method as many times as nodes in query' do
        expect(hash_query).to receive(:build_query).exactly(4).times.and_call_original
        hash_query.build_query(filter, [])
      end
    end
  end

  describe '.handle_association' do
    context 'when all is correct' do
      it 'calls .build_query method with the given parameters' do
        parameters = {}
        base = []
        association = :OR
        expect(hash_query).to receive(:build_query).with(parameters, base, association)
        hash_query.handle_association(parameters, base, association)
      end
    end

    context 'when :paramaters is not a Hash' do
      it 'raises an InvalidQuery exception' do
        expect do # Number
          hash_query.handle_association(Faker::Number.number(3).to_i, true, :OR)
        end.to raise_error TDJobs::InvalidQuery
        expect do # String
          hash_query.handle_association(Faker::Lorem.word, [], :OR)
        end.to raise_error TDJobs::InvalidQuery
        expect do # Array
          hash_query.handle_association(Faker::Lorem.words, [], :OR)
        end.to raise_error TDJobs::InvalidQuery
      end
    end

    context 'when :association is not included in the ALLOWED list' do
      it 'raises an InvalidQuery exception' do
        expect do # ANDA
          hash_query.handle_association({}, [], :ANDA)
        end.to raise_error TDJobs::InvalidQuery
        expect do # XOR
          hash_query.handle_association({}, [], :$XOR)
        end.to raise_error TDJobs::InvalidQuery
        expect do # ORAND
          hash_query.handle_association({}, [], :ORAND)
        end.to raise_error TDJobs::InvalidQuery
      end
    end
  end

  describe '.operator' do
    context 'when the modifier is valid' do
      it 'returns the symbol associated' do
        expect(hash_query.operator(:gt)).to eq ">"
        expect(hash_query.operator(:lt)).to eq "<"
        expect(hash_query.operator(:geq)).to eq ">="
        expect(hash_query.operator(:leq)).to eq "<="
        expect(hash_query.operator(:like)).to eq "LIKE"
        expect(hash_query.operator(:in)).to eq "IN"
      end
    end

    context 'when the modifier doesn\'t exist' do
      it 'raises an InvalidQuery exception' do
        expect { hash_query.operator(:yoyo) }.to raise_error TDJobs::InvalidQuery
        expect { hash_query.operator(:yolo) }.to raise_error TDJobs::InvalidQuery
        expect { hash_query.operator(:likeing) }.to raise_error TDJobs::InvalidQuery
        expect { hash_query.operator(:less) }.to raise_error TDJobs::InvalidQuery
        expect { hash_query.operator(:great) }.to raise_error TDJobs::InvalidQuery
      end
    end
  end
  #
  describe '.setup_condition' do
    context 'when the modifier is :like and condition Number' do
      let(:condition) { Faker::Number.number(5).to_i }
      let(:expected_condition) { "%#{condition}%" }
      it 'returns the number stringified and surrounded by \'%\'' do
        expect(hash_query.setup_condition(:like, condition)).to eq expected_condition
      end
    end

    context 'when the modifier is :like and condition Float' do
      let(:condition) { Faker::Number.decimal(5).to_f }
      let(:expected_condition) { "%#{condition}%" }
      it 'returns the float stringified and surrounded by \'%\'' do
        expect(hash_query.setup_condition(:like, condition)).to eq expected_condition
      end
    end

    context 'when the modifier is :like and condition String' do
      let(:condition) { Faker::Lorem.word }
      let(:expected_condition) { "%#{condition}%" }
      it 'returns the string surrounded by \'%\'' do
        expect(hash_query.setup_condition(:like, condition)).to eq expected_condition
      end
    end

    context 'when the modifier is :in and condition String Array' do
      let(:condition) { Faker::Lorem.words }
      it 'returns the same array without modifications' do
        expect(hash_query.setup_condition(:in, condition)).to eq condition
      end
    end

    context 'when the modifier is :in and condition not String Array' do
      let(:condition) { Faker::Lorem.words.append(Faker::Number.number(3).to_i) }
      it 'raises a InvalidQuery exception' do
        expect { hash_query.setup_condition(:in, condition) }.to raise_error TDJobs::InvalidQuery
      end
    end

    context 'when the modifier is :in and condition String' do
      let(:condition) { Faker::Lorem.word }
      it 'raises an InvalidQuery exception' do
        expect { hash_query.setup_condition(:in, condition) }.to raise_error TDJobs::InvalidQuery
      end
    end

    context 'when the modifier is :in and condition Number' do
      let(:condition) { Faker::Number.number(1).to_i }
      it 'raises an InvalidQuery exception' do
        expect { hash_query.setup_condition(:in, condition) }.to raise_error TDJobs::InvalidQuery
      end
    end

    context 'when the modifier is an inequality and condition String' do
      let(:condition) { Faker::Lorem.word }
      it 'returns the same string without modifications' do
        expect(hash_query.setup_condition(:gt, condition)).to eq condition
        expect(hash_query.setup_condition(:lt, condition)).to eq condition
        expect(hash_query.setup_condition(:geq, condition)).to eq condition
        expect(hash_query.setup_condition(:leq, condition)).to eq condition
      end
    end

    context 'when the modifier is an inequality and condition Number' do
      let(:condition) { Faker::Number.number(5).to_i }
      it 'returns the stringified number' do
        expect(hash_query.setup_condition(:gt, condition)).to eq condition.to_s
        expect(hash_query.setup_condition(:lt, condition)).to eq condition.to_s
        expect(hash_query.setup_condition(:geq, condition)).to eq condition.to_s
        expect(hash_query.setup_condition(:leq, condition)).to eq condition.to_s
      end
    end

    context 'when the modifier is an inequality and condition Array' do
      let(:condition) { Faker::Lorem.words(Faker::Number.number(1).to_i) }
      it 'returns an InvalidQuery exception' do
        expect { hash_query.setup_condition(:gt, condition) }.to raise_error TDJobs::InvalidQuery
        expect { hash_query.setup_condition(:lt, condition) }.to raise_error TDJobs::InvalidQuery
        expect { hash_query.setup_condition(:geq, condition) }.to raise_error TDJobs::InvalidQuery
        expect { hash_query.setup_condition(:leq, condition) }.to raise_error TDJobs::InvalidQuery
      end
    end
  end

  describe '.job_query' do
    context 'when the query has an invalid format' do
      it 'raises a JSONError exception' do
        expect { hash_query.send(:job_query, "{invalid json") }.to raise_error JSON::JSONError
      end
    end

    context 'when no filters are given' do
      it 'raises an InvalidQuery exception' do
        expect { hash_query.send(:job_query, "{}") }.to raise_error TDJobs::InvalidQuery
      end
    end

    context 'when all given filters are invalid' do
      let(:filter) do
        { hi: Faker::Lorem.word, bye: Faker::Number.number(4) }
      end
      it 'raises an InvalidQuery exception' do
        expect do
          hash_query.send(:job_query, filter.to_json)
        end.to raise_error TDJobs::InvalidQuery
      end
    end

    context 'when there is one filter invalid' do
      let(:filter) do
          { description: Faker::Lorem.paragraph, name: Faker::Lorem.name,
            hello: Faker::Number.number(1), owner_id: Faker::Lorem.word }
      end
      it 'raises an InvalidQuery exception' do
        expect do
          hash_query.send(:job_query, filter.to_json)
        end.to raise_error TDJobs::InvalidQuery
      end
    end

    context 'when all given filters are valid' do
      let(:filter) { "{\"description\":\"My description\", \"owner_id\": {\"like\": \"hey\" } }"}
      let(:expected) do
        { description: "My description", owner_id: { 'like' => 'hey' } }.stringify_keys!
      end
      it 'returns the Hash version of the filter' do
        expect(hash_query.send(:job_query, filter)).to eq expected
      end
    end
  end
end
