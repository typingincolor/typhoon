require 'sequel'

class Task < Sequel::Model
  plugin :timestamps, update_on_create: true
  plugin :validation_helpers

  def validate
    super
    validates_presence [:url, :at]
    validates_format URI::DEFAULT_PARSER.make_regexp(%w[http https]), :url, message: 'must be a valid HTTP(S) URL'
  end

  def self.pending
    where(completed_at: nil).where { at <= Time.now }
  end

  def mark_completed!(response_code:, result_id:)
    update(
      completed_at: Time.now,
      code: response_code,
      result: result_id
    )
  end

  def completed?
    !completed_at.nil?
  end
end
