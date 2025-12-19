require_relative '../spec_helper'

RSpec.describe Config do
  describe '.load!' do
    it 'loads configuration for test environment' do
      Config.load!('test')

      expect(Config.settings).to be_a(Hash)
      expect(Config.settings[:env]).to eq('test')
    end

    it 'provides access to app config' do
      Config.load!('test')

      expect(Config.app).to have_key(:port)
      expect(Config.app).to have_key(:host)
    end

    it 'provides access to database config' do
      Config.load!('test')

      expect(Config.database).to have_key(:database)
    end

    it 'provides access to email config' do
      Config.load!('test')

      expect(Config.email).to have_key(:from)
      expect(Config.email).to have_key(:delivery_method)
    end

    it 'provides access to moneta config' do
      Config.load!('test')

      expect(Config.moneta).to have_key(:adapter)
    end
  end

  describe 'explicit accessor methods' do
    before { Config.load!('test') }

    it 'provides app config via accessor method' do
      expect(Config.app).to be_a(Hash)
      expect(Config.app).to have_key(:port)
    end

    it 'provides database config via accessor method' do
      expect(Config.database).to be_a(Hash)
      expect(Config.database).to have_key(:database)
    end

    it 'provides email config via accessor method' do
      expect(Config.email).to be_a(Hash)
      expect(Config.email).to have_key(:from)
    end

    it 'provides moneta config via accessor method' do
      expect(Config.moneta).to be_a(Hash)
      expect(Config.moneta).to have_key(:adapter)
    end

    it 'provides env via accessor method' do
      expect(Config.env).to eq('test')
    end
  end

  describe 'hash-like access' do
    before { Config.load!('test') }

    it 'supports [] notation for dynamic access' do
      expect(Config[:app]).to be_a(Hash)
      expect(Config[:database]).to be_a(Hash)
    end
  end

  describe 'environment-specific settings' do
    it 'uses test database for test environment' do
      Config.load!('test')

      expect(Config.database[:database]).to eq('test.sqlite')
    end

    it 'uses memory store for test environment' do
      Config.load!('test')

      expect(Config.moneta[:adapter]).to eq('Memory')
    end
  end

  describe 'deep symbolization' do
    before { Config.load!('test') }

    it 'symbolizes top-level keys' do
      expect(Config.settings.keys).to all(be_a(Symbol))
    end

    it 'symbolizes nested keys' do
      expect(Config.app.keys).to all(be_a(Symbol))
      expect(Config.database.keys).to all(be_a(Symbol))
    end
  end
end
