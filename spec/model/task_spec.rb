require_relative '../spec_helper'

RSpec.describe Task do
  describe 'validations' do
    it 'is valid with url and at' do
      task = Task.new(url: 'http://example.com', at: Time.now)

      expect(task.valid?).to be true
    end

    it 'is invalid without url' do
      task = Task.new(at: Time.now)

      expect(task.valid?).to be false
      expect(task.errors[:url]).not_to be_empty
    end

    it 'is invalid without at' do
      task = Task.new(url: 'http://example.com')

      expect(task.valid?).to be false
      expect(task.errors[:at]).not_to be_empty
    end

    it 'is invalid with malformed URL' do
      task = Task.new(url: 'not a url', at: Time.now)

      expect(task.valid?).to be false
      expect(task.errors[:url]).not_to be_empty
    end

    it 'accepts https URLs' do
      task = Task.new(url: 'https://example.com/path', at: Time.now)

      expect(task.valid?).to be true
    end

    it 'rejects non-http(s) URLs' do
      task = Task.new(url: 'ftp://example.com', at: Time.now)

      expect(task.valid?).to be false
    end
  end

  describe '.pending' do
    it 'returns tasks due now with nil completed_at' do
      past_task = Task.create(url: 'http://example.com/1', at: Time.now - 3600)
      Task.create(url: 'http://example.com/2', at: Time.now + 3600)
      Task.create(url: 'http://example.com/3', at: Time.now - 3600, completed_at: Time.now)

      pending = Task.pending.all

      expect(pending).to include(past_task)
      expect(pending.length).to eq(1)
    end

    it 'returns empty array when no tasks are pending' do
      Task.create(url: 'http://example.com', at: Time.now + 3600)

      expect(Task.pending.all).to be_empty
    end
  end

  describe '#mark_completed!' do
    it 'marks task as completed with response code and result' do
      task = Task.create(url: 'http://example.com', at: Time.now)

      task.mark_completed!(response_code: 200, result_id: '123')
      task.reload

      expect(task.completed_at).not_to be_nil
      expect(task.code).to eq(200)
      expect(task.result).to eq('123')
    end

    it 'sets completed_at to current time' do
      task = Task.create(url: 'http://example.com', at: Time.now)
      before_time = Time.now

      task.mark_completed!(response_code: 200, result_id: '1')
      task.reload

      expect(task.completed_at).to be >= before_time
      expect(task.completed_at).to be <= Time.now
    end
  end

  describe '#completed?' do
    it 'returns true when task has completed_at' do
      task = Task.create(url: 'http://example.com', at: Time.now, completed_at: Time.now)

      expect(task.completed?).to be true
    end

    it 'returns false when task has no completed_at' do
      task = Task.create(url: 'http://example.com', at: Time.now)

      expect(task.completed?).to be false
    end
  end

  describe 'timestamps' do
    it 'sets created_at and updated_at on create' do
      task = Task.create(url: 'http://example.com', at: Time.now)

      expect(task.created_at).not_to be_nil
      expect(task.updated_at).not_to be_nil
    end

    it 'updates updated_at on save' do
      task = Task.create(url: 'http://example.com', at: Time.now)
      original_updated_at = task.updated_at

      sleep 0.01 # Ensure time difference
      task.update(code: 200)

      expect(task.updated_at).to be > original_updated_at
    end
  end
end
