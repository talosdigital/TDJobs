require 'rails_helper'

describe TDJobs do
  it 'should respond to :configuration' do
    expect(TDJobs).to respond_to :configuration
  end

  it 'should respond to :configure' do
    expect(TDJobs).to respond_to :configure
  end

  describe '.configure' do
    it 'should set the configuration from within a block' do
      TDJobs.configure do |config|
        config.auto_close_jobs = false
        config.autoinvite = false
      end
      expect(TDJobs.configuration.auto_close_jobs?).to eq false
      expect(TDJobs.configuration.autoinvite?).to eq false
    end
  end
end

describe TDJobs::Configuration do
  it 'should respond to :autoinvite' do
    expect(TDJobs.configuration).to respond_to :autoinvite?
    expect(TDJobs.configuration).to respond_to :autoinvite=
  end

  it 'should respond to :auto_close_jobs' do
    expect(TDJobs.configuration).to respond_to :auto_close_jobs?
    expect(TDJobs.configuration).to respond_to :auto_close_jobs=
  end

  it 'should respond to :application_secret' do
    expect(TDJobs.configuration).to respond_to :application_secret
    expect(TDJobs.configuration).to respond_to :application_secret=
  end

  context 'when options have default values' do
    it 'should return false for :autoinvite' do
      TDJobs.configuration.autoinvite = nil # Supposing that was not initialized.
      expect(TDJobs.configuration.autoinvite?).to eq false
    end

    it 'should return false for :auto_close_jobs' do
      TDJobs.configuration.auto_close_jobs = nil # Supposing that was not initialized.
      expect(TDJobs.configuration.auto_close_jobs?).to eq false
    end
  end
end
