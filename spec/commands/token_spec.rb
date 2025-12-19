require_relative '../spec_helper'
require_relative '../../commands/Token'

RSpec.describe Token do
  describe '#initialize' do
    it 'creates a token with empty body and headers by default' do
      token = Token.new

      expect(token.body).to eq('')
      expect(token.headers).to eq([])
    end

    it 'creates a token with custom body' do
      token = Token.new(body: 'test body')

      expect(token.body).to eq('test body')
    end

    it 'creates a token with custom headers' do
      headers = [{ header: 'Test', value: 'Value' }]
      token = Token.new(headers: headers)

      expect(token.headers).to eq(headers)
    end
  end

  describe '#add_header' do
    it 'adds a header to the token' do
      token = Token.new
      token.add_header(header: 'Content-Type', value: 'application/json')

      expect(token.headers).to eq([{ header: 'Content-Type', value: 'application/json' }])
    end

    it 'returns self for chaining' do
      token = Token.new
      result = token.add_header(header: 'Test', value: 'Value')

      expect(result).to be(token)
    end

    it 'allows multiple headers' do
      token = Token.new
      token.add_header(header: 'First', value: '1')
      token.add_header(header: 'Second', value: '2')

      expect(token.headers.length).to eq(2)
    end
  end

  describe '#set_body' do
    it 'sets the body' do
      token = Token.new
      token.set_body('new body')

      expect(token.body).to eq('new body')
    end

    it 'returns self for chaining' do
      token = Token.new
      result = token.set_body('test')

      expect(result).to be(token)
    end

    it 'overwrites existing body' do
      token = Token.new(body: 'old')
      token.set_body('new')

      expect(token.body).to eq('new')
    end
  end

  describe '#get_body' do
    it 'returns the current body' do
      token = Token.new(body: 'test body')

      expect(token.get_body).to eq('test body')
    end
  end

  describe '#get' do
    it 'returns a hash with headers and body' do
      token = Token.new(body: 'test', headers: [{ header: 'H', value: 'V' }])
      result = token.get

      expect(result).to eq({ headers: [{ header: 'H', value: 'V' }], body: 'test' })
    end
  end

  describe '#to_json' do
    it 'returns JSON representation' do
      token = Token.new(body: 'test')
      json = JSON.parse(token.to_json)

      expect(json['body']).to eq('test')
      expect(json['headers']).to eq([])
    end
  end

  describe 'chaining' do
    it 'allows method chaining' do
      token = Token.new

      result = token
        .add_header(header: 'First', value: '1')
        .set_body('body')
        .add_header(header: 'Second', value: '2')

      expect(result.body).to eq('body')
      expect(result.headers.length).to eq(2)
    end
  end
end
